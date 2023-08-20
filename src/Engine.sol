// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {ConditionalOrderHashLib} from
    "src/libraries/ConditionalOrderHashLib.sol";
import {EIP712} from "src/utils/EIP712.sol";
import {ERC721Receivable} from "src/utils/ERC721Receivable.sol";
import {IEngine} from "src/interfaces/IEngine.sol";
import {IERC20} from "src/interfaces/tokens/IERC20.sol";
import {IERC721} from "src/interfaces/tokens/IERC721.sol";
import {Int128Lib} from "src/libraries/Int128Lib.sol";
import {Int256Lib} from "src/libraries/Int256Lib.sol";
import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";
import {IPyth, PythStructs} from "src/interfaces/oracles/IPyth.sol";
import {ISpotMarketProxy} from "src/interfaces/synthetix/ISpotMarketProxy.sol";
import {Multicallable} from "src/utils/Multicallable.sol";
import {SignatureCheckerLib} from "src/libraries/SignatureCheckerLib.sol";

/// @title Kwenta Smart Margin v3: Engine contract
/// @notice Responsible for interacting with Synthetix v3 perps markets
/// @author JaredBorders (jaredborders@pm.me)
contract Engine is IEngine, Multicallable, EIP712, ERC721Receivable {
    using Int128Lib for int128;
    using Int256Lib for int256;
    using SignatureCheckerLib for bytes;
    using ConditionalOrderHashLib for OrderDetails;
    using ConditionalOrderHashLib for ConditionalOrder;

    /// @notice tracking code submitted with trades to identify the source of the trade
    bytes32 internal constant TRACKING_CODE = "KWENTA";

    /// @notice admins have permission to do everything that the account owner can
    /// (including granting and revoking permissions for other addresses) except
    /// for transferring account ownership
    bytes32 internal constant ADMIN_PERMISSION = "ADMIN";

    /// @notice the address of the kwenta treasury multisig; used for source of collecting fees
    address internal constant REFERRER =
        0xF510a2Ff7e9DD7e18629137adA4eb56B9c13E885;

    /// @notice pyth oracle contract used to get asset prices
    IPyth internal immutable ORACLE;

    /// @notice pyth price feed id for ETH/USD
    bytes32 immutable PYTH_ETH_USD_ID;

    /// @notice Synthetix v3 perps market proxy contract
    IPerpsMarketProxy internal immutable PERPS_MARKET_PROXY;

    /// @notice Synthetix v3 spot market proxy contract
    ISpotMarketProxy internal immutable SPOT_MARKET_PROXY;

    /// @notice Synthetix v3 sUSD contract
    IERC20 internal immutable SUSD;

    /// @notice mapping that stores stats for an account
    mapping(uint128 accountId => AccountStats) internal accountStats;

    /// @notice mapping that stores if an order with a given nonce has been executed
    mapping(uint128 nonce => bool) public executedOrders;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Constructs the Engine contract
    /// @param _perpsMarketProxy Synthetix v3 perps market proxy contract
    /// @param _spotMarketProxy Synthetix v3 spot market proxy contract
    /// @param _sUSDProxy Synthetix v3 sUSD contract
    constructor(
        address _perpsMarketProxy,
        address _spotMarketProxy,
        address _sUSDProxy,
        address _oracle,
        bytes32 _pythPriceFeedIdEthUsd
    ) {
        PERPS_MARKET_PROXY = IPerpsMarketProxy(_perpsMarketProxy);
        SPOT_MARKET_PROXY = ISpotMarketProxy(_spotMarketProxy);
        SUSD = IERC20(_sUSDProxy);
        ORACLE = IPyth(_oracle);
        PYTH_ETH_USD_ID = _pythPriceFeedIdEthUsd;
    }

    /*//////////////////////////////////////////////////////////////
                             CREATE ACCOUNT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEngine
    function createAccount() external override returns (uint128 accountId) {
        accountId = PERPS_MARKET_PROXY.createAccount();

        PERPS_MARKET_PROXY.grantPermission({
            accountId: accountId,
            permission: ADMIN_PERMISSION,
            user: address(this)
        });

        IERC721 accountNftToken =
            IERC721(PERPS_MARKET_PROXY.getAccountTokenAddress());
        accountNftToken.safeTransferFrom(address(this), msg.sender, accountId);
    }

    /*//////////////////////////////////////////////////////////////
                                 STATS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEngine
    function getAccountStats(uint128 _accountId)
        external
        view
        returns (AccountStats memory)
    {
        return accountStats[_accountId];
    }

    /// @notice update the stats of an account
    /// @param _accountId the account to update
    /// @param _fees the fees to add to the account
    /// @param _volume the volume to add to the account
    /// @dev only callable by a validated margin engine
    function _updateAccountStats(
        uint128 _accountId,
        uint256 _fees,
        uint128 _volume
    ) internal {
        AccountStats storage stats = accountStats[_accountId];

        stats.totalFees += _fees;
        stats.totalVolume += _volume;
        stats.totalTrades++;
    }

    /*//////////////////////////////////////////////////////////////
                             AUTHENTICATION
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEngine
    function isAccountOwner(uint128 _accountId, address _caller)
        public
        view
        override
        returns (bool)
    {
        return PERPS_MARKET_PROXY.getAccountOwner(_accountId) == _caller;
    }

    /// @inheritdoc IEngine
    function isAccountDelegate(uint128 _accountId, address _caller)
        public
        view
        override
        returns (bool)
    {
        return PERPS_MARKET_PROXY.hasPermission(
            _accountId, ADMIN_PERMISSION, _caller
        );
    }

    /*//////////////////////////////////////////////////////////////
                         COLLATERAL MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEngine
    function modifyCollateral(
        uint128 _accountId,
        uint128 _synthMarketId,
        int256 _amount
    ) external override {
        IERC20 synth = IERC20(_getSynthAddress(_synthMarketId));

        if (_amount > 0) {
            _depositCollateral(synth, _accountId, _synthMarketId, _amount);
        } else {
            if (!isAccountOwner(_accountId, msg.sender)) revert Unauthorized();
            _withdrawCollateral(synth, _accountId, _synthMarketId, _amount);
        }
    }

    function _depositCollateral(
        IERC20 _synth,
        uint128 _accountId,
        uint128 _synthMarketId,
        int256 _amount
    ) internal {
        // @dev given the amount is positive, simply casting (int -> uint) is safe
        _synth.transferFrom(msg.sender, address(this), uint256(_amount));

        _synth.approve(address(PERPS_MARKET_PROXY), uint256(_amount));

        PERPS_MARKET_PROXY.modifyCollateral(_accountId, _synthMarketId, _amount);
    }

    function _withdrawCollateral(
        IERC20 _synth,
        uint128 _accountId,
        uint128 _synthMarketId,
        int256 _amount
    ) internal {
        PERPS_MARKET_PROXY.modifyCollateral(_accountId, _synthMarketId, _amount);

        /// @dev given the amount is negative, simply casting (int -> uint) is unsafe, thus we use .abs()
        _synth.transfer(msg.sender, _amount.abs());
    }

    /// @notice query and return the address of the synth contract
    /// @param _synthMarketId the id of the synth market
    /// @return  synthAddress address of the synth based on the synth market id
    function _getSynthAddress(uint128 _synthMarketId)
        internal
        view
        returns (address synthAddress)
    {
        /// @dev "0" synthMarketId represents sUSD in Synthetix v3
        synthAddress = _synthMarketId == 0
            ? address(SUSD)
            : SPOT_MARKET_PROXY.getSynth(_synthMarketId);
    }

    /*//////////////////////////////////////////////////////////////
                         ASYNC ORDER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEngine
    function commitOrder(
        uint128 _perpsMarketId,
        uint128 _accountId,
        int128 _sizeDelta,
        uint128 _settlementStrategyId,
        uint256 _acceptablePrice
    ) external override {
        /// @dev only the account owner can withdraw collateral
        if (
            isAccountOwner(_accountId, msg.sender)
                || isAccountDelegate(_accountId, msg.sender)
        ) {
            _commitOrder({
                _perpsMarketId: _perpsMarketId,
                _accountId: _accountId,
                _sizeDelta: _sizeDelta,
                _settlementStrategyId: _settlementStrategyId,
                _acceptablePrice: _acceptablePrice
            });
        } else {
            revert Unauthorized();
        }
    }

    function _commitOrder(
        uint128 _perpsMarketId,
        uint128 _accountId,
        int128 _sizeDelta,
        uint128 _settlementStrategyId,
        uint256 _acceptablePrice
    ) internal {
        (, uint256 fees) = PERPS_MARKET_PROXY.commitOrder(
            IPerpsMarketProxy.OrderCommitmentRequest({
                marketId: _perpsMarketId,
                accountId: _accountId,
                sizeDelta: _sizeDelta,
                settlementStrategyId: _settlementStrategyId,
                acceptablePrice: _acceptablePrice,
                trackingCode: TRACKING_CODE,
                referrer: REFERRER
            })
        );

        _updateAccountStats(_accountId, fees, _sizeDelta.abs());
    }

    /*//////////////////////////////////////////////////////////////
                      CONDITIONAL ORDER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEngine
    function execute(ConditionalOrder calldata _co, bytes calldata _signature)
        external
    {
        executedOrders[_co.nonce] = true;

        (bool canExecuteOrder, uint256 gasSpentUSD) =
            canExecute(_co, _signature);

        if (!canExecuteOrder) revert CannotExecuteOrder();

        /// @custom:todo figure out gas used for modifyCollateral & commitOrder
        uint256 fee = gasSpentUSD + 0; // 0 is the gas used for modifyCollateral & commitOrder

        _withdrawCollateral({
            _synth: SUSD,
            _accountId: _co.orderDetails.accountId,
            _synthMarketId: 0,
            _amount: -int256(fee)
        });

        _commitOrder(
            _co.orderDetails.marketId,
            _co.orderDetails.accountId,
            _co.orderDetails.sizeDelta,
            _co.orderDetails.settlementStrategyId,
            _co.orderDetails.acceptablePrice
        );
    }

    /// @inheritdoc IEngine
    function canExecute(
        ConditionalOrder calldata _co,
        bytes calldata _signature
    ) public returns (bool, uint256) {
        uint256 gas = gasleft();

        /// @dev reverts if the price has not been updated
        /// within the last `getValidTimePeriod()` seconds
        PythStructs.Price memory priceData = ORACLE.getPrice(PYTH_ETH_USD_ID);
        /// @custom:todo determine if we need to use the exponent
        uint64 price = uint64(priceData.price); // uint64 price = uint64(priceData.price) * 10**uint32(priceData.expo);

        // verify nonce has not been executed before
        if (executedOrders[_co.nonce]) return (false, 0);

        // verify signer is authorized to interact with the account
        if (!verifySigner(_co)) return (false, 0);

        // verify signature is valid for signer and order
        if (!verifySignature(_co, _signature)) return (false, 0);

        // verify conditions are met
        if (_co.requireVerified) {
            // if the order requires verification, then all conditions
            // defined by "conditions" for the order must be met
            if (!verifyConditions(_co)) return (false, 0);
        } else {
            // if the order does not require verification, then the caller
            // must be the trusted executor defined by "trustedExecutor"
            if (msg.sender != _co.trustedExecutor) return (false, 0);
        }

        // determine how much margin is available to withdraw
        /// @custom:todo getWithdrawableMargin vs getRequiredMargins vs totalCollateralValue vs getCollateralAmount
        /// @custom:todo figure out how to *SAFELY* pull sUSD from account without causing a liquidation
        int256 withdrawableMargin =
            PERPS_MARKET_PROXY.getWithdrawableMargin(_co.orderDetails.accountId);

        // if enough margin is available to withdraw to pay for the order execution, then return true
        if (
            withdrawableMargin > 0
                && uint256(withdrawableMargin) > gas - gasleft() * price
        ) {
            return (true, gas - gasleft() * price);
        }

        return (false, 0);
    }

    /*//////////////////////////////////////////////////////////////
                     CONDITIONAL ORDER VERIFICATION
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEngine
    function verifySigner(ConditionalOrder calldata _co)
        public
        view
        returns (bool)
    {
        if (
            isAccountOwner(_co.orderDetails.accountId, _co.signer)
                || isAccountDelegate(_co.orderDetails.accountId, _co.signer)
        ) {
            return true;
        }

        return false;
    }

    /// @inheritdoc IEngine
    function verifySignature(
        ConditionalOrder calldata _co,
        bytes calldata _signature
    ) public view returns (bool) {
        bool isValid = _signature.isValidSignatureNowCalldata(
            _hashTypedData(_co.hash()), _co.signer
        );

        return isValid;
    }

    /// @inheritdoc IEngine
    function verifyConditions(ConditionalOrder calldata _co)
        public
        returns (bool)
    {
        uint256 length = _co.conditions.length;
        for (uint256 i = 0; i < length; i++) {
            (bool success, bytes memory response) =
                address(this).call(_co.conditions[i]);
            if (!success || !abi.decode(response, (bool))) return false;
        }

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                               CONDITIONS
    //////////////////////////////////////////////////////////////*/

    /// @custom:todo add documentation
    function isTimestampAfter(uint256 _timestamp) public view returns (bool) {
        return block.timestamp > _timestamp;
    }

    /// @custom:todo add documentation
    function isTimestampBefore(uint256 _timestamp) public view returns (bool) {
        return block.timestamp < _timestamp;
    }

    /// @custom:todo add documentation
    function isPriceAbove(uint256 price) public pure returns (bool) {
        return price == type(uint256).max ? false : true;
    }

    /// @custom:todo add documentation
    function isPriceBelow(uint256 price) public pure returns (bool) {
        return price == 0 ? false : true;
    }

    /// @custom:todo add documentation
    function isMarketPaused(address market) public pure returns (bool) {
        return market == address(0) ? true : false;
    }

    /// @custom:todo add documentation
    function isMarketClosed(address market) public pure returns (bool) {
        return market == address(0) ? true : false;
    }
}

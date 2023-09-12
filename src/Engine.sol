// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {ConditionalOrderHashLib} from
    "src/libraries/ConditionalOrderHashLib.sol";
import {EIP712} from "src/utils/EIP712.sol";
import {ERC721Receivable} from "src/utils/ERC721Receivable.sol";
import {IEngine, IPerpsMarketProxy} from "src/interfaces/IEngine.sol";
import {IERC20} from "src/interfaces/tokens/IERC20.sol";
import {IERC721} from "src/interfaces/tokens/IERC721.sol";
import {IPyth, PythStructs} from "src/interfaces/oracles/IPyth.sol";
import {ISpotMarketProxy} from "src/interfaces/synthetix/ISpotMarketProxy.sol";
import {MathLib} from "src/libraries/MathLib.sol";
import {Multicallable} from "src/utils/Multicallable.sol";
import {SignatureCheckerLib} from "src/libraries/SignatureCheckerLib.sol";

/// @title Kwenta Smart Margin v3: Engine contract
/// @notice Responsible for interacting with Synthetix v3 perps markets
/// @author JaredBorders (jaredborders@pm.me)
contract Engine is IEngine, Multicallable, EIP712, ERC721Receivable {
    using MathLib for int128;
    using MathLib for int256;
    using MathLib for uint256;
    using SignatureCheckerLib for bytes;
    using ConditionalOrderHashLib for OrderDetails;
    using ConditionalOrderHashLib for ConditionalOrder;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice admins have permission to do everything that the account owner can
    /// (including granting and revoking permissions for other addresses) except
    /// for transferring account ownership
    bytes32 internal constant ADMIN_PERMISSION = "ADMIN";

    /// @notice "0" synthMarketId represents sUSD in Synthetix v3
    uint128 internal constant USD_SYNTH_ID = 0;

    /// @notice max fee that can be charged for a conditional order execution
    /// @dev 50 USD
    uint256 public constant UPPER_FEE_CAP = 50 ether;

    /// @notice min fee that can be charged for a conditional order execution
    /// @dev 2 USD
    uint256 public constant LOWER_FEE_CAP = 2 ether;

    /// @notice percentage of the simulated order fee that is charged for a conditional order execution
    /// @dev denoted in BPS (basis points) where 1% = 100 BPS and 100% = 10000 BPS
    uint256 public constant FEE_SCALING_FACTOR = 1000;

    /// @notice max BPS
    uint256 internal constant MAX_BPS = 10_000;

    /// @notice max number of conditions that can be defined for a conditional order
    uint256 internal constant MAX_CONDITIONS = 5;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice pyth oracle contract used to get asset prices
    IPyth internal immutable ORACLE;

    /// @notice Synthetix v3 perps market proxy contract
    IPerpsMarketProxy internal immutable PERPS_MARKET_PROXY;

    /// @notice Synthetix v3 spot market proxy contract
    ISpotMarketProxy internal immutable SPOT_MARKET_PROXY;

    /// @notice Synthetix v3 sUSD contract
    IERC20 internal immutable SUSD;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

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
        address _oracle
    ) {
        if (_perpsMarketProxy == address(0)) revert ZeroAddress();
        if (_spotMarketProxy == address(0)) revert ZeroAddress();
        if (_sUSDProxy == address(0)) revert ZeroAddress();
        if (_oracle == address(0)) revert ZeroAddress();

        PERPS_MARKET_PROXY = IPerpsMarketProxy(_perpsMarketProxy);
        SPOT_MARKET_PROXY = ISpotMarketProxy(_spotMarketProxy);
        SUSD = IERC20(_sUSDProxy);
        ORACLE = IPyth(_oracle);
    }

    /*//////////////////////////////////////////////////////////////
                             CREATE ACCOUNT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEngine
    function createAccount() external override returns (uint128 accountId) {
        accountId = PERPS_MARKET_PROXY.createAccount();

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
        override
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
        uint128 _fees,
        uint128 _volume
    ) internal {
        AccountStats storage stats = accountStats[_accountId];

        stats.totalFees += _fees;
        stats.totalVolume += _volume;
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
            _depositCollateral(
                msg.sender, synth, _accountId, _synthMarketId, _amount
            );
        } else {
            if (!isAccountOwner(_accountId, msg.sender)) revert Unauthorized();
            _withdrawCollateral(
                msg.sender, synth, _accountId, _synthMarketId, _amount
            );
        }
    }

    function _depositCollateral(
        address _from,
        IERC20 _synth,
        uint128 _accountId,
        uint128 _synthMarketId,
        int256 _amount
    ) internal {
        // @dev given the amount is positive, simply casting (int -> uint) is safe
        _synth.transferFrom(_from, address(this), uint256(_amount));

        _synth.approve(address(PERPS_MARKET_PROXY), uint256(_amount));

        PERPS_MARKET_PROXY.modifyCollateral(_accountId, _synthMarketId, _amount);
    }

    function _withdrawCollateral(
        address _to,
        IERC20 _synth,
        uint128 _accountId,
        uint128 _synthMarketId,
        int256 _amount
    ) internal {
        PERPS_MARKET_PROXY.modifyCollateral(_accountId, _synthMarketId, _amount);

        /// @dev given the amount is negative, simply casting (int -> uint) is unsafe, thus we use .abs()
        _synth.transfer(_to, _amount.abs256());
    }

    /// @notice query and return the address of the synth contract
    /// @param _synthMarketId the id of the synth market
    /// @return  synthAddress address of the synth based on the synth market id
    function _getSynthAddress(uint128 _synthMarketId)
        internal
        view
        returns (address synthAddress)
    {
        synthAddress = _synthMarketId == USD_SYNTH_ID
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
        uint256 _acceptablePrice,
        bytes32 _trackingCode,
        address _referrer
    )
        external
        override
        returns (IPerpsMarketProxy.Data memory retOrder, uint256 fees)
    {
        /// @dev only the account owner can withdraw collateral
        if (
            isAccountOwner(_accountId, msg.sender)
                || isAccountDelegate(_accountId, msg.sender)
        ) {
            (retOrder, fees) = _commitOrder({
                _perpsMarketId: _perpsMarketId,
                _accountId: _accountId,
                _sizeDelta: _sizeDelta,
                _settlementStrategyId: _settlementStrategyId,
                _acceptablePrice: _acceptablePrice,
                _trackingCode: _trackingCode,
                _referrer: _referrer
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
        uint256 _acceptablePrice,
        bytes32 _trackingCode,
        address _referrer
    ) internal returns (IPerpsMarketProxy.Data memory retOrder, uint256 fees) {
        (retOrder, fees) = PERPS_MARKET_PROXY.commitOrder(
            IPerpsMarketProxy.OrderCommitmentRequest({
                marketId: _perpsMarketId,
                accountId: _accountId,
                sizeDelta: _sizeDelta,
                settlementStrategyId: _settlementStrategyId,
                acceptablePrice: _acceptablePrice,
                trackingCode: _trackingCode,
                referrer: _referrer
            })
        );

        _updateAccountStats(_accountId, fees.castU128(), _sizeDelta.abs128());
    }

    /*//////////////////////////////////////////////////////////////
                      CONDITIONAL ORDER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEngine
    function execute(ConditionalOrder calldata _co, bytes calldata _signature)
        external
        override
        returns (
            IPerpsMarketProxy.Data memory retOrder,
            uint256 fees,
            uint256 conditionalOrderFee
        )
    {
        /// @dev check: (1) nonce has not been executed before
        /// @dev check: (2) signer is authorized to interact with the account
        /// @dev check: (3) signature for the order was signed by the signer
        /// @dev check: (4) conditions are met || trusted executor is msg sender
        if (!canExecute(_co, _signature)) revert CannotExecuteOrder();

        /// @dev mark the nonce as executed; prevents replay
        executedOrders[_co.nonce] = true;

        /// @notice get size delta from order details
        /// @dev up to the caller to not waste gas by passing in a size delta of zero
        int128 sizeDelta = _co.orderDetails.sizeDelta;

        /// @notice handle reduce only orders
        if (_co.orderDetails.isReduceOnly) {
            (,, int128 positionSize) = PERPS_MARKET_PROXY.getOpenPosition(
                _co.orderDetails.accountId, _co.orderDetails.marketId
            );

            // ensure position exists; reduce only orders cannot increase position size
            if (positionSize == 0) {
                return (retOrder, 0, 0);
            }

            // ensure incoming size delta is NOT the same sign; i.e. reduce only orders cannot increase position size
            if (positionSize.isSameSign(sizeDelta)) {
                return (retOrder, 0, 0);
            }

            // ensure incoming size delta is not larger than current position size
            /// @dev reduce only orders can only reduce position size (i.e. approach size of zero) and
            /// cannot cross that boundary (i.e. short -> long or long -> short)
            if (sizeDelta.abs128() > positionSize.abs128()) {
                sizeDelta = -positionSize;
            }
        }

        /// @dev fetch estimated order fees to be used to
        /// calculate conditional order fee
        (uint256 orderFees,) = PERPS_MARKET_PROXY.computeOrderFees({
            marketId: _co.orderDetails.marketId,
            sizeDelta: sizeDelta
        });

        /// @dev calculate conditional order fee based on scaled order fees
        conditionalOrderFee = (orderFees * FEE_SCALING_FACTOR) / MAX_BPS;

        /// @dev ensure conditional order fee is within bounds
        if (conditionalOrderFee < LOWER_FEE_CAP) {
            conditionalOrderFee = LOWER_FEE_CAP;
        } else if (conditionalOrderFee > UPPER_FEE_CAP) {
            conditionalOrderFee = UPPER_FEE_CAP;
        }

        /// @dev withdraw conditional order fee from account prior to executing order
        _withdrawCollateral({
            _to: msg.sender,
            _synth: SUSD,
            _accountId: _co.orderDetails.accountId,
            _synthMarketId: USD_SYNTH_ID,
            _amount: -int256(conditionalOrderFee)
        });

        /// @dev execute the order
        (retOrder, fees) = _commitOrder(
            _co.orderDetails.marketId,
            _co.orderDetails.accountId,
            sizeDelta,
            _co.orderDetails.settlementStrategyId,
            _co.orderDetails.acceptablePrice,
            _co.orderDetails.trackingCode,
            _co.orderDetails.referrer
        );
    }

    /// @inheritdoc IEngine
    function canExecute(
        ConditionalOrder calldata _co,
        bytes calldata _signature
    ) public view override returns (bool) {
        // verify nonce has not been executed before
        if (executedOrders[_co.nonce]) return false;

        // verify signer is authorized to interact with the account
        if (!verifySigner(_co)) return false;

        // verify signature is valid for signer and order
        if (!verifySignature(_co, _signature)) return false;

        // verify conditions are met
        if (_co.requireVerified) {
            // if the order requires verification, then all conditions
            // defined by "conditions" for the order must be met
            if (!verifyConditions(_co)) return false;
        } else {
            // if the order does not require verification, then the caller
            // must be the trusted executor defined by "trustedExecutor"
            if (msg.sender != _co.trustedExecutor) return false;
        }

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                     CONDITIONAL ORDER VERIFICATION
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEngine
    function verifySigner(ConditionalOrder calldata _co)
        public
        view
        override
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
    ) public view override returns (bool) {
        bool isValid = _signature.isValidSignatureNowCalldata(
            _hashTypedData(_co.hash()), _co.signer
        );

        return isValid;
    }

    /// @inheritdoc IEngine
    function verifyConditions(ConditionalOrder calldata _co)
        public
        view
        override
        returns (bool)
    {
        uint256 length = _co.conditions.length;
        if (length > MAX_CONDITIONS) revert MaxConditionSizeExceeded();
        for (uint256 i = 0; i < length;) {
            bool success;
            bytes memory response;

            /// @dev staticcall to prevent state changes in the case a condition is malicious
            (success, response) = address(this).staticcall(_co.conditions[i]);

            if (!success || !abi.decode(response, (bool))) return false;

            unchecked {
                i++;
            }
        }

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                               CONDITIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEngine
    function isTimestampAfter(uint256 _timestamp)
        public
        view
        override
        returns (bool)
    {
        return block.timestamp > _timestamp;
    }

    /// @inheritdoc IEngine
    function isTimestampBefore(uint256 _timestamp)
        public
        view
        override
        returns (bool)
    {
        return block.timestamp < _timestamp;
    }

    /// @inheritdoc IEngine
    function isPriceAbove(
        bytes32 _assetId,
        int64 _price,
        uint64 _confidenceInterval
    ) public view override returns (bool) {
        PythStructs.Price memory priceData = ORACLE.getPrice(_assetId);

        /// @dev although counterintuitive, a smaller confidence interval is more accurate.
        /// The Engine must ensure the current confidence interval is not
        /// greater (i.e. less accurate) than the confidence interval defined by the condition.
        return priceData.price > _price && priceData.conf <= _confidenceInterval;
    }

    /// @inheritdoc IEngine
    function isPriceBelow(
        bytes32 _assetId,
        int64 _price,
        uint64 _confidenceInterval
    ) public view override returns (bool) {
        PythStructs.Price memory priceData = ORACLE.getPrice(_assetId);

        /// @dev although counterintuitive, a smaller confidence interval is more accurate.
        /// The Engine must ensure the current confidence interval is not
        /// greater (i.e. less accurate) than the confidence interval defined by the condition.
        return priceData.price < _price && priceData.conf <= _confidenceInterval;
    }

    /// @inheritdoc IEngine
    function isMarketOpen(uint128 _marketId)
        public
        view
        override
        returns (bool)
    {
        return
            PERPS_MARKET_PROXY.getMaxMarketSize(_marketId) == 0 ? false : true;
    }
}

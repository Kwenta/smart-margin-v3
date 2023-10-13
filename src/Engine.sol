// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {ConditionalOrderHashLib} from
    "src/libraries/ConditionalOrderHashLib.sol";
import {EIP712} from "src/utils/EIP712.sol";
import {EIP7412} from "src/utils/EIP7412.sol";
import {ERC2771Context} from "lib/trusted-multicall-forwarder/lib/openzeppelin-contracts/contracts/metatx/ERC2771Context.sol";
import {IEngine, IPerpsMarketProxy} from "src/interfaces/IEngine.sol";
import {IERC20} from "src/interfaces/tokens/IERC20.sol";
import {IPyth, PythStructs} from "src/interfaces/oracles/IPyth.sol";
import {ISpotMarketProxy} from "src/interfaces/synthetix/ISpotMarketProxy.sol";
import {MathLib} from "src/libraries/MathLib.sol";
import {SignatureCheckerLib} from "src/libraries/SignatureCheckerLib.sol";

/// @title Kwenta Smart Margin v3: Engine contract
/// @notice Responsible for interacting with Synthetix v3 perps markets
/// @author JaredBorders (jaredborders@pm.me)
contract Engine is IEngine, EIP712, EIP7412, ERC2771Context {
    using MathLib for int128;
    using MathLib for int256;
    using MathLib for uint256;
    using SignatureCheckerLib for bytes;
    using ConditionalOrderHashLib for ConditionalOrder;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice the permission required to commit an async order
    /// @dev this permission does not allow the permission holder to modify collateral
    bytes32 internal constant PERPS_COMMIT_ASYNC_ORDER_PERMISSION =
        "PERPS_COMMIT_ASYNC_ORDER";

    /// @notice "0" synthMarketId represents sUSD in Synthetix v3
    uint128 internal constant USD_SYNTH_ID = 0;

    /// @notice max number of conditions that can be defined for a conditional order
    uint256 internal constant MAX_CONDITIONS = 8;

    /// @notice condition selector constant(s)
    bytes4 internal constant isTimestampAfterSelector =
        IEngine.isTimestampAfter.selector;
    bytes4 internal constant isTimestampBeforeSelector =
        IEngine.isTimestampBefore.selector;
    bytes4 internal constant isPriceAboveSelector =
        IEngine.isPriceAbove.selector;
    bytes4 internal constant isPriceBelowSelector =
        IEngine.isPriceBelow.selector;
    bytes4 internal constant isMarketOpenSelector =
        IEngine.isMarketOpen.selector;
    bytes4 internal constant isPositionSizeAboveSelector =
        IEngine.isPositionSizeAbove.selector;
    bytes4 internal constant isPositionSizeBelowSelector =
        IEngine.isPositionSizeBelow.selector;
    bytes4 internal constant isOrderFeeBelowSelector =
        IEngine.isOrderFeeBelow.selector;

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

    /// @notice bit mapping that stores whether a conditional order nonce has been executed
    /// @dev nonce is specific to the account id associated with the conditional order
    mapping(uint128 accountId => mapping(uint256 index => uint256 bitmap))
        public nonceBitmap;

    /// @notice mapping of account id to ETH balance
    /// @dev ETH can be deposited/withdrawn from the
    /// Engine contract to pay for fee(s) (conditional order execution, etc.)
    mapping(uint128 accountId => uint256 ethBalance) public ethBalances;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Constructs the Engine contract
    /// @param _perpsMarketProxy Synthetix v3 perps market proxy contract
    /// @param _spotMarketProxy Synthetix v3 spot market proxy contract
    /// @param _sUSDProxy Synthetix v3 sUSD contract
    /// @param _oracle pyth oracle contract used to get asset prices
    /// @param _trustedForwarder trusted forwarder contract used for meta transactions
    constructor(
        address _perpsMarketProxy,
        address _spotMarketProxy,
        address _sUSDProxy,
        address _oracle,
        address _trustedForwarder
    ) ERC2771Context(_trustedForwarder) {
        if (_perpsMarketProxy == address(0)) revert ZeroAddress();
        if (_spotMarketProxy == address(0)) revert ZeroAddress();
        if (_sUSDProxy == address(0)) revert ZeroAddress();
        if (_oracle == address(0)) revert ZeroAddress();
        if (_trustedForwarder == address(0)) revert ZeroAddress();

        PERPS_MARKET_PROXY = IPerpsMarketProxy(_perpsMarketProxy);
        SPOT_MARKET_PROXY = ISpotMarketProxy(_spotMarketProxy);
        SUSD = IERC20(_sUSDProxy);
        ORACLE = IPyth(_oracle);
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
        external
        view
        override
        returns (bool)
    {
        return PERPS_MARKET_PROXY.hasPermission(
            _accountId, PERPS_COMMIT_ASYNC_ORDER_PERMISSION, _caller
        );
    }

    function _isAccountOwnerOrDelegate(uint128 _accountId, address _caller)
        internal
        view
        returns (bool)
    {
        return PERPS_MARKET_PROXY.isAuthorized(
            _accountId, PERPS_COMMIT_ASYNC_ORDER_PERMISSION, _caller
        );
    }

    /*//////////////////////////////////////////////////////////////
                             ETH MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEngine
    function depositEth(uint128 _accountId) external payable override {
        ethBalances[_accountId] += msg.value;

        emit EthDeposit(_accountId, msg.value);
    }

    /// @inheritdoc IEngine
    function withdrawEth(uint128 _accountId, uint256 _amount)
        external
        override
    {
        address payable caller = payable(_msgSender());

        if (!isAccountOwner(_accountId, caller)) revert Unauthorized();

        _withdrawEth(caller, _accountId, _amount);

        emit EthWithdraw(_accountId, _amount);
    }

    /// @notice debit ETH from the account and transfer it to the caller
    /// @dev UNSAFE to call directly; use `withdrawEth` instead
    /// @param _caller the caller of the function
    /// @param _accountId the account id to debit ETH from
    function _withdrawEth(
        address payable _caller,
        uint128 _accountId,
        uint256 _amount
    ) internal {
        if (_amount > ethBalances[_accountId]) revert InsufficientEthBalance();

        // decrement the ETH balance of the account prior to transferring ETH to the caller
        ethBalances[_accountId] -= _amount;

        (bool sent,) = _caller.call{value: _amount}("");

        if (!sent) revert EthTransferFailed();
    }

    /*//////////////////////////////////////////////////////////////
                            NONCE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEngine
    function invalidateUnorderedNonces(
        uint128 _accountId,
        uint256 _wordPos,
        uint256 _mask
    ) external override {
        if (_isAccountOwnerOrDelegate(_accountId, _msgSender())) {
            /// @dev using bitwise OR to set the bit at the bit position
            /// bitmap          = .......10001
            /// mask            = .......00110
            /// bitmap | mask   = .......10111
            /// notice all set bits in the mask are now set in the bitmap
            nonceBitmap[_accountId][_wordPos] |= _mask;

            emit UnorderedNonceInvalidation(_accountId, _wordPos, _mask);
        } else {
            revert Unauthorized();
        }
    }

    /// @inheritdoc IEngine
    function hasUnorderedNonceBeenUsed(uint128 _accountId, uint256 _nonce)
        public
        view
        override
        returns (bool)
    {
        (uint256 wordPos, uint256 bitPos) = _bitmapPositions(_nonce);

        /// @dev given bitPos == 2
        /// .......00001 becomes .......00100
        uint256 bit = 1 << bitPos;

        /// @dev given wordPos == 0 and *assume* some bits at
        /// other bit positions were already set (but not the bit at the bit position)
        /// bit             = .......00100
        /// bitmap          = .......10001
        /// bitmap & bit    = .......00000
        /// thus in this case, bitmap & bit == 0 (nonce has not been used)
        ///
        /// @dev if the bit at the bit position was already set, then the nonce has been used before
        /// bit             = .......00100
        /// bitmap          = .......10101 (notice the bit at the bit position is already set)
        /// bitmap & bit    = .......00100
        /// thus in this case, bitmap & bit != 0 (nonce has been used)
        return nonceBitmap[_accountId][wordPos] & bit != 0;
    }

    /// @notice fetch the index of the bitmap and the bit position within
    /// the bitmap. used for *unordered* nonces
    /// @param _nonce the nonce to get the associated word and bit positions
    /// @return wordPos the word position **or index** into the nonceBitmap
    /// @return bitPos the bit position
    /// @dev The first 248 bits of the nonce value is the index of the desired bitmap
    /// @dev The last 8 bits of the nonce value is the position of the bit in the bitmap
    function _bitmapPositions(uint256 _nonce)
        internal
        pure
        returns (uint256 wordPos, uint256 bitPos)
    {
        // shift _nonce to the right by 8 bits and cast to uint248
        /// @dev wordPos == 0 if 0 <= _nonce <= 255, 1 if 256 <= _nonce <= 511, etc.
        wordPos = uint248(_nonce >> 8);

        // cast the last 8 bits of _nonce to uint8
        /// @dev 0 <= bitPos <= 255
        bitPos = uint8(_nonce);
    }

    /// @notice checks whether a nonce is taken and sets the bit at the bit position in the bitmap at the word position
    /// @param _accountId the account id to use the nonce at
    /// @param _nonce The nonce to spend
    function _useUnorderedNonce(uint128 _accountId, uint256 _nonce) internal {
        (uint256 wordPos, uint256 bitPos) = _bitmapPositions(_nonce);

        /// @dev given bitPos == 2
        /// .......00001 becomes .......00100
        uint256 bit = 1 << bitPos;

        /// @dev given wordPos == 0 and *assume* some bits at
        /// other bit positions were already set (but not the bit at the bit position)
        /// bit             = .......00100
        /// bitmap          = .......10001
        /// flipped         = .......10101
        uint256 flipped = nonceBitmap[_accountId][wordPos] ^= bit;

        /// @dev is the bit at the bit position was already set, then the nonce has been used before
        /// (refer to the example above, but this time assume the bit at the bit position was already set)
        /// bit             = .......00100
        /// bitmap          = .......10101 (notice the bit at the bit position is already set)
        /// flipped         = .......10001
        /// thus in this case, flipped & bit == 0
        /// flipped         = .......10001
        /// bit             = .......00100
        /// flipped & bit   = .......00000
        ///
        /// @dev if the bit at the bit position was not already set, then the nonce has not been used before
        /// bit             = .......00100
        /// bitmap          = .......10001 (notice the bit at the bit position is (not set)
        /// flipped         = .......10101
        /// thus in this case, flipped & bit != 0
        /// flipped         = .......10101
        /// bit             = .......00100
        /// flipped & bit   = .......00100
        if (flipped & bit == 0) revert InvalidNonce();
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

        address caller = _msgSender();

        if (_amount > 0) {
            _depositCollateral(
                caller, synth, _accountId, _synthMarketId, _amount
            );
        } else {
            if (!isAccountOwner(_accountId, caller)) revert Unauthorized();
            _withdrawCollateral(
                caller, synth, _accountId, _synthMarketId, _amount
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
        if (_isAccountOwnerOrDelegate(_accountId, _msgSender())) {
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
    }

    /*//////////////////////////////////////////////////////////////
                      CONDITIONAL ORDER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEngine
    function execute(
        ConditionalOrder calldata _co,
        bytes calldata _signature,
        uint256 _fee
    )
        external
        override
        returns (IPerpsMarketProxy.Data memory retOrder, uint256 fees)
    {
        /// @dev check: (1) fee does not exceed the max fee set by the conditional order
        /// @dev check: (2) fee does not exceed balance credited to the account
        /// @dev check: (3) nonce has not been executed before
        /// @dev check: (4) signer is authorized to interact with the account
        /// @dev check: (5) signature for the order was signed by the signer
        /// @dev check: (6) conditions are met || trusted executor is msg sender
        if (!canExecute(_co, _signature, _fee)) revert CannotExecuteOrder();

        /// @dev spend the nonce associated with the order; this prevents replay
        _useUnorderedNonce(_co.orderDetails.accountId, _co.nonce);

        /// @dev impose a fee for executing the conditional order
        /// @dev the fee is denoted in ETH and is paid to the caller (conditional order executor)
        /// @dev the fee does not exceed the max fee set by the conditional order and
        /// this is enforced by the `canExecute` function
        _withdrawEth(payable(_msgSender()), _co.orderDetails.accountId, _fee);

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
                return (retOrder, 0);
            }

            // ensure incoming size delta is NOT the same sign; i.e. reduce only orders cannot increase position size
            if (positionSize.isSameSign(sizeDelta)) {
                return (retOrder, 0);
            }

            // ensure incoming size delta is not larger than current position size
            /// @dev reduce only orders can only reduce position size (i.e. approach size of zero) and
            /// cannot cross that boundary (i.e. short -> long or long -> short)
            if (sizeDelta.abs128() > positionSize.abs128()) {
                /// @dev if the value of sizeDelta was used to verify `isOrderFeeBelow`
                /// condition prior to it being truncated *here*, the actual order fee
                /// (see below) will always be less than the order fee estimated during
                /// that condition check.
                /// @custom:integrator This is important to understand because if a reduce-only order
                /// sets size delta to type(int128).min/max (to basically close a position),
                /// the order fee will appear to be extremely large during the condition check, but will be
                /// much smaller when the order is actually executed due to the size delta being
                /// truncated to the current position size *here*.
                sizeDelta = -positionSize;
            }
        }

        /// @dev execute the order
        (retOrder, fees) = _commitOrder({
            _perpsMarketId: _co.orderDetails.marketId,
            _accountId: _co.orderDetails.accountId,
            _sizeDelta: sizeDelta,
            _settlementStrategyId: _co.orderDetails.settlementStrategyId,
            _acceptablePrice: _co.orderDetails.acceptablePrice,
            _trackingCode: _co.orderDetails.trackingCode,
            _referrer: _co.orderDetails.referrer
        });
    }

    /// @inheritdoc IEngine
    function canExecute(
        ConditionalOrder calldata _co,
        bytes calldata _signature,
        uint256 _fee
    ) public view override returns (bool) {
        // verify fee does not exceed the max fee set by the conditional order
        if (_fee > _co.maxExecutorFee) return false;

        // verify account has enough credit (ETH) to pay the fee
        if (_fee > ethBalances[_co.orderDetails.accountId]) return false;

        // verify nonce has not been executed before
        if (hasUnorderedNonceBeenUsed(_co.orderDetails.accountId, _co.nonce)) {
            return false;
        }

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
            if (_msgSender() != _co.trustedExecutor) return false;
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
        return _isAccountOwnerOrDelegate(_co.orderDetails.accountId, _co.signer);
    }

    /// @inheritdoc IEngine
    function verifySignature(
        ConditionalOrder calldata _co,
        bytes calldata _signature
    ) public view override returns (bool) {
        return _signature.isValidSignatureNowCalldata(
            _hashTypedData(_co.hash()), _co.signer
        );
    }

    /// @inheritdoc IEngine
    function verifyConditions(ConditionalOrder calldata _co)
        public
        view
        override
        returns (bool)
    {
        uint256 length = _co.conditions.length;
        if (length > MAX_CONDITIONS) {
            revert MaxConditionSizeExceeded();
        }

        for (uint256 i = 0; i < length;) {
            bool success;
            bytes memory response;

            // define condition selector intended to be called
            bytes4 selector = bytes4(_co.conditions[i]);

            /// @dev checking if the selector is valid prevents the possibility of
            /// a malicious condition from griefing the executor
            if (
                selector == isTimestampAfterSelector
                    || selector == isTimestampBeforeSelector
                    || selector == isPriceAboveSelector
                    || selector == isPriceBelowSelector
                    || selector == isMarketOpenSelector
                    || selector == isPositionSizeAboveSelector
                    || selector == isPositionSizeBelowSelector
                    || selector == isOrderFeeBelowSelector
            ) {
                // @dev staticcall to prevent state changes in the case a condition is malicious
                (success, response) =
                    address(this).staticcall(_co.conditions[i]);

                if (!success || !abi.decode(response, (bool))) return false;

                unchecked {
                    i++;
                }
            } else {
                revert InvalidConditionSelector(selector);
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
        return PERPS_MARKET_PROXY.getMaxMarketSize(_marketId) != 0;
    }

    /// @inheritdoc IEngine
    function isPositionSizeAbove(
        uint128 _accountId,
        uint128 _marketId,
        int128 _size
    ) public view override returns (bool) {
        (,, int128 positionSize) =
            PERPS_MARKET_PROXY.getOpenPosition(_accountId, _marketId);

        return positionSize > _size;
    }

    /// @inheritdoc IEngine
    function isPositionSizeBelow(
        uint128 _accountId,
        uint128 _marketId,
        int128 _size
    ) public view override returns (bool) {
        (,, int128 positionSize) =
            PERPS_MARKET_PROXY.getOpenPosition(_accountId, _marketId);

        return positionSize < _size;
    }

    /// @inheritdoc IEngine
    function isOrderFeeBelow(uint128 _marketId, int128 _sizeDelta, uint256 _fee)
        public
        view
        override
        returns (bool)
    {
        (uint256 orderFees,) = PERPS_MARKET_PROXY.computeOrderFees({
            marketId: _marketId,
            sizeDelta: _sizeDelta
        });

        return orderFees < _fee;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {ConditionalOrderHashLib} from
    "src/libraries/ConditionalOrderHashLib.sol";
import {EIP712} from "src/utils/EIP712.sol";
import {EIP7412} from "src/utils/EIP7412.sol";
import {IEngine, IPerpsMarketProxy} from "src/interfaces/IEngine.sol";
import {IERC20} from "src/interfaces/tokens/IERC20.sol";
import {ISpotMarketProxy} from "src/interfaces/synthetix/ISpotMarketProxy.sol";
import {MathLib} from "src/libraries/MathLib.sol";
import {MulticallablePayable} from "src/utils/MulticallablePayable.sol";
import {SignatureCheckerLib} from "src/libraries/SignatureCheckerLib.sol";
import {Zap} from "lib/zap/src/Zap.sol";

/// @custom:upgradability
import {UUPSUpgradeable} from
    "lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";

/// @title Kwenta Smart Margin v3: Engine contract
/// @notice Responsible for interacting with
/// Synthetix v3 perps markets
/// @custom:caution Engine should never hold an
/// ETH balance so long as it is MulticallablePayable
/// @custom:caution Add payable functions to the Engine
/// with extreme caution
/// @author JaredBorders (jaredborders@pm.me)
contract Engine is
    IEngine,
    EIP712,
    EIP7412,
    MulticallablePayable,
    Zap,
    UUPSUpgradeable
{
    using MathLib for int128;
    using MathLib for int256;
    using MathLib for uint256;
    using ConditionalOrderHashLib for ConditionalOrder;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice the permission required to commit an async order
    /// @dev this permission does not allow the permission
    /// holder to modify collateral
    bytes32 internal constant PERPS_COMMIT_ASYNC_ORDER_PERMISSION =
        "PERPS_COMMIT_ASYNC_ORDER";

    /// @notice "0" synthMarketId represents $sUSD in Synthetix v3
    uint128 internal constant USD_SYNTH_ID = 0;

    /// @notice max number of conditions that can be defined
    /// for a conditional order
    uint256 internal constant MAX_CONDITIONS = 8;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Kwenta owned/operated multisig address that
    /// can authorize upgrades
    /// @dev if this address is the zero address, then the
    /// Engine will no longer be upgradeable
    /// @dev making immutable because the pDAO address
    /// will *never* change
    address internal immutable pDAO;

    /// @notice Synthetix v3 perps market proxy contract
    IPerpsMarketProxy internal immutable PERPS_MARKET_PROXY;

    /// @notice Synthetix v3 spot market proxy contract
    ISpotMarketProxy internal immutable SPOT_MARKET_PROXY;

    /// @notice Synthetix v3 $sUSD contract
    IERC20 internal immutable SUSD;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @dev reserved storage space for future contract upgrades
    /// @custom:caution reduce storage size when adding new storage variables
    uint256[19] private __gap;

    /// @notice bit mapping that stores whether a conditional
    /// order nonce has been executed
    /// @dev nonce is specific to the account id associated
    /// with the conditional order
    mapping(uint128 accountId => mapping(uint256 index => uint256 bitmap))
        public nonceBitmap;

    /// @notice mapping of account id to $sUSD balance
    /// (i.e. credit available to pay for fee(s))
    /// @dev $sUSD can be credited to the Engine to pay for fee(s)
    mapping(uint128 accountId => uint256) public credit;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Constructs the Engine contract
    /// @dev Zap constructor will revert if any of the
    /// addresses are zero
    /// @param _perpsMarketProxy Synthetix v3 perps
    /// market proxy contract
    /// @param _spotMarketProxy Synthetix v3 spot
    /// market proxy contract
    /// @param _sUSDProxy Synthetix v3 $sUSD contract
    /// @param _pDAO Kwenta owned/operated multisig address
    /// that can authorize upgrades
    /// @param _usdc $USDC token contract address
    /// @param _sUSDCId Synthetix v3 Spot Market ID for $sUSDC
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address _perpsMarketProxy,
        address _spotMarketProxy,
        address _sUSDProxy,
        address _pDAO,
        address _usdc,
        uint128 _sUSDCId
    ) Zap(_usdc, _sUSDProxy, _spotMarketProxy, _sUSDCId) {
        if (_perpsMarketProxy == address(0)) revert ZeroAddress();

        PERPS_MARKET_PROXY = IPerpsMarketProxy(_perpsMarketProxy);
        SPOT_MARKET_PROXY = ISpotMarketProxy(_spotMarketProxy);
        SUSD = IERC20(_sUSDProxy);

        /// @dev pDAO address can be the zero address to
        /// make the Engine non-upgradeable
        pDAO = _pDAO;
    }

    /*//////////////////////////////////////////////////////////////
                           UPGRADE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address /* _newImplementation */ )
        internal
        view
        override
    {
        if (pDAO == address(0)) revert NonUpgradeable();
        if (msg.sender != pDAO) revert OnlyPDAO();
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
        return _caller != address(0)
            && PERPS_MARKET_PROXY.getAccountOwner(_accountId) == _caller;
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
        return _caller != address(0)
            && PERPS_MARKET_PROXY.isAuthorized(
                _accountId, PERPS_COMMIT_ASYNC_ORDER_PERMISSION, _caller
            );
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
        if (_isAccountOwnerOrDelegate(_accountId, msg.sender)) {
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
        /// other bit positions were already set
        /// (but not the bit at the bit position)
        /// bit             = .......00100
        /// bitmap          = .......10001
        /// bitmap & bit    = .......00000
        /// thus in this case, bitmap & bit == 0
        /// (nonce has not been used)
        ///
        /// @dev if the bit at the bit position was already set,
        /// then the nonce has been used before
        /// bit             = .......00100
        /// bitmap          = .......10101 (notice the bit at the bit position is already set)
        /// bitmap & bit    = .......00100
        /// thus in this case, bitmap & bit != 0 (nonce has been used)
        return nonceBitmap[_accountId][wordPos] & bit != 0;
    }

    /// @notice fetch the index of the bitmap and
    /// the bit position within
    /// the bitmap. used for *unordered* nonces
    /// @param _nonce the nonce to get the associated
    /// word and bit positions
    /// @return wordPos the word position **or index**
    /// into the nonceBitmap
    /// @return bitPos the bit position
    /// @dev The first 248 bits of the nonce value is
    /// the index of the desired bitmap
    /// @dev The last 8 bits of the nonce value is the
    /// position of the bit in the bitmap
    function _bitmapPositions(uint256 _nonce)
        internal
        pure
        returns (uint256 wordPos, uint256 bitPos)
    {
        // shift _nonce to the right by 8 bits and
        /// cast to uint248
        /// @dev wordPos == 0 if 0 <= _nonce <= 255,
        /// 1 if 256 <= _nonce <= 511, etc.
        wordPos = _nonce >> 8;

        // cast the last 8 bits of _nonce to uint8
        /// @dev 0 <= bitPos <= 255
        bitPos = uint8(_nonce);
    }

    /// @notice checks whether a nonce is taken and
    /// sets the bit at the bit position in the bitmap
    /// at the word position
    /// @param _accountId the account id to use the nonce at
    /// @param _nonce The nonce to spend
    function _useUnorderedNonce(uint128 _accountId, uint256 _nonce) internal {
        (uint256 wordPos, uint256 bitPos) = _bitmapPositions(_nonce);

        /// @dev given bitPos == 2
        /// .......00001 becomes .......00100
        uint256 bit = 1 << bitPos;

        /// @dev given wordPos == 0 and *assume* some bits at
        /// other bit positions were already set
        /// (but not the bit at the bit position)
        /// bit             = .......00100
        /// bitmap          = .......10001
        /// flipped         = .......10101
        uint256 flipped = nonceBitmap[_accountId][wordPos] ^= bit;

        /// @dev is the bit at the bit position was already
        /// set, then the nonce has been used before
        /// (refer to the example above, but this time
        /// assume the bit at the bit position was already set)
        /// bit             = .......00100
        /// bitmap          = .......10101 (notice the bit at the bit position is already set)
        /// flipped         = .......10001
        /// thus in this case, flipped & bit == 0
        /// flipped         = .......10001
        /// bit             = .......00100
        /// flipped & bit   = .......00000
        ///
        /// @dev if the bit at the bit position was not already
        /// set, then the nonce has not been used before
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

    /// @inheritdoc IEngine
    function modifyCollateralZap(uint128 _accountId, int256 _amount)
        external
        override
    {
        if (_amount > 0) {
            // zap $USDC -> $sUSD
            /// @dev given the amount is positive,
            /// simply casting (int -> uint) is safe
            uint256 susdAmount = _zapIn(uint256(_amount));

            SUSD.approve(address(PERPS_MARKET_PROXY), susdAmount);

            PERPS_MARKET_PROXY.modifyCollateral(
                _accountId, USD_SYNTH_ID, susdAmount.toInt256()
            );
        } else {
            if (!isAccountOwner(_accountId, msg.sender)) revert Unauthorized();

            PERPS_MARKET_PROXY.modifyCollateral(
                _accountId, USD_SYNTH_ID, _amount
            );

            // zap $sUSD -> $USDC
            /// @dev given the amount is negative,
            /// simply casting (int -> uint) is unsafe, thus we use .abs()
            uint256 usdcAmount = _zapOut(_amount.abs256());

            /// @dev transfer return value can be safely ignored
            _USDC.transfer(msg.sender, usdcAmount);
        }
    }

    function _depositCollateral(
        address _from,
        IERC20 _synth,
        uint128 _accountId,
        uint128 _synthMarketId,
        int256 _amount
    ) internal {
        /// @dev given the amount is positive,
        /// simply casting (int -> uint) is safe
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

        /// @dev given the amount is negative,
        /// simply casting (int -> uint) is unsafe, thus we use .abs()
        _synth.transfer(_to, _amount.abs256());
    }

    /// @notice query and return the address of
    /// the synth contract
    /// @param _synthMarketId the id of the synth market
    /// @return  synthAddress address of the synth based
    /// on the synth market id
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
        /// @dev the account owner or the delegate
        /// may commit async orders
        if (_isAccountOwnerOrDelegate(_accountId, msg.sender)) {
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
                           CREDIT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEngine
    function creditAccount(uint128 _accountId, uint256 _amount)
        external
        override
    {
        credit[_accountId] += _amount;

        /// @dev $sUSD transfers that fail will revert
        SUSD.transferFrom(msg.sender, address(this), _amount);

        emit Credited(_accountId, _amount);
    }

    /// @inheritdoc IEngine
    function creditAccountZap(uint128 _accountId, uint256 _amount)
        external
        override
    {
        // zap $USDC -> $sUSD
        uint256 usdcAmount = _zapIn(_amount);

        credit[_accountId] += usdcAmount;

        emit Credited(_accountId, usdcAmount);
    }

    /// @inheritdoc IEngine
    function debitAccount(uint128 _accountId, uint256 _amount)
        external
        override
    {
        if (!isAccountOwner(_accountId, msg.sender)) revert Unauthorized();

        _debit(msg.sender, _accountId, _amount);

        emit Debited(_accountId, _amount);
    }

    /// @inheritdoc IEngine
    function debitAccountZap(uint128 _accountId, uint256 _amount)
        external
        override
    {
        if (!isAccountOwner(_accountId, msg.sender)) revert Unauthorized();

        // decrement account credit prior to transfer
        credit[_accountId] -= _amount;

        // zap $sUSD -> $USDC
        uint256 usdcAmount = _zapOut(_amount);

        /// @dev transfer return value can be safely ignored
        _USDC.transfer(msg.sender, usdcAmount);

        emit Debited(_accountId, _amount);
    }

    function _debit(address _caller, uint128 _accountId, uint256 _amount)
        internal
    {
        if (_amount > credit[_accountId]) revert InsufficientCredit();

        // decrement account credit prior to transfer
        credit[_accountId] -= _amount;

        /// @dev $sUSD transfers that fail will revert
        SUSD.transfer(_caller, _amount);
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
        returns (IPerpsMarketProxy.Data memory retOrder, uint256 synthetixFees)
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
        /// @dev the fee is denoted in $sUSD and is
        /// paid to the caller (conditional order executor)
        /// @dev the fee does not exceed the max fee set by
        /// the conditional order and
        /// this is enforced by the `canExecute` function
        if (_fee > 0) _debit(msg.sender, _co.orderDetails.accountId, _fee);

        /// @notice get size delta from order details
        int128 sizeDelta = _co.orderDetails.sizeDelta;

        /// @notice handle reduce only orders
        if (_co.orderDetails.isReduceOnly) {
            (,, int128 positionSize) = PERPS_MARKET_PROXY.getOpenPosition(
                _co.orderDetails.accountId, _co.orderDetails.marketId
            );

            // ensure position exists; reduce only orders
            // cannot increase position size
            if (positionSize == 0) {
                revert CannotExecuteOrder();
            }

            // ensure incoming size delta is non-zero and
            // NOT the same sign;
            // i.e. reduce only orders cannot increase position size
            if (sizeDelta == 0 || positionSize.isSameSign(sizeDelta)) {
                revert CannotExecuteOrder();
            }

            // ensure incoming size delta is not larger
            // than current position size
            /// @dev reduce only orders can only reduce
            /// position size (i.e. approach size of zero) and
            /// cannot cross that boundary
            /// (i.e. short -> long or long -> short)
            if (sizeDelta.abs128() > positionSize.abs128()) {
                /// @dev if the value of sizeDelta was
                /// used to verify `isOrderFeeBelow`
                /// condition prior to it being truncated *here*,
                /// the actual order fee
                /// (see below) will always be less than the
                /// order fee estimated during that condition check.
                /// @custom:integrator This is important to understand
                /// because if a reduce-only order
                /// sets size delta to type(int128).min/max
                /// (to basically close a position),
                /// the order fee will appear to be extremely large
                /// during the condition check, but will be
                /// much smaller when the order is actually executed
                /// due to the size delta being
                /// truncated to the current position size *here*.
                sizeDelta = -positionSize;
            }
        }

        /// @dev commit async order
        (retOrder, synthetixFees) = _commitOrder({
            _perpsMarketId: _co.orderDetails.marketId,
            _accountId: _co.orderDetails.accountId,
            _sizeDelta: sizeDelta,
            _settlementStrategyId: _co.orderDetails.settlementStrategyId,
            _acceptablePrice: _co.orderDetails.acceptablePrice,
            _trackingCode: _co.orderDetails.trackingCode,
            _referrer: _co.orderDetails.referrer
        });

        emit ConditionalOrderExecuted({
            order: retOrder,
            synthetixFees: synthetixFees,
            executorFee: _fee
        });
    }

    /// @inheritdoc IEngine
    function canExecute(
        ConditionalOrder calldata _co,
        bytes calldata _signature,
        uint256 _fee
    ) public view override returns (bool) {
        // verify fee does not exceed the max fee
        // set by the conditional order
        if (_fee > _co.maxExecutorFee) return false;

        // verify account has enough credit to pay the fee
        if (_fee > credit[_co.orderDetails.accountId]) return false;

        // verify nonce has not been executed before
        if (hasUnorderedNonceBeenUsed(_co.orderDetails.accountId, _co.nonce)) {
            return false;
        }

        // verify signer is authorized to interact
        // with the account
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
        return _isAccountOwnerOrDelegate(_co.orderDetails.accountId, _co.signer);
    }

    /// @inheritdoc IEngine
    function verifySignature(
        ConditionalOrder calldata _co,
        bytes calldata _signature
    ) public view override returns (bool) {
        return SignatureCheckerLib.isValidSignatureNowCalldata({
            signer: _co.signer,
            hash: _hashTypedData(_co.hash()),
            signature: _signature
        });
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

            /// @dev checking if the selector is
            /// valid prevents the possibility of
            /// a malicious condition from griefing the executor
            if (
                selector == this.isPriceAbove.selector
                    || selector == this.isPriceBelow.selector
                    || selector == this.isTimestampAfter.selector
                    || selector == this.isTimestampBefore.selector
                    || selector == this.isMarketOpen.selector
                    || selector == this.isPositionSizeAbove.selector
                    || selector == this.isPositionSizeBelow.selector
                    || selector == this.isOrderFeeBelow.selector
            ) {
                /// @dev staticcall to prevent state changes
                /// in the case a condition is malicious
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
    function isPriceAbove(uint128 _marketId, uint256 _price, int128 _size)
        public
        view
        override
        returns (bool)
    {
        (, uint256 fillPrice) = PERPS_MARKET_PROXY.computeOrderFees({
            marketId: _marketId,
            sizeDelta: _size
        });

        return fillPrice > _price;
    }

    /// @inheritdoc IEngine
    function isPriceBelow(uint128 _marketId, uint256 _price, int128 _size)
        public
        view
        override
        returns (bool)
    {
        (, uint256 fillPrice) = PERPS_MARKET_PROXY.computeOrderFees({
            marketId: _marketId,
            sizeDelta: _size
        });

        return fillPrice < _price;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Engine} from "src/Engine.sol";
import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";
import {SignatureCheckerLib} from "src/libraries/SignatureCheckerLib.sol";
import {EIP712} from "src/utils/EIP712.sol";
import {Ownable} from "src/utils/Ownable.sol";

/// @title Kwenta Smart Margin v3: Order Book Module
/// @notice Responsible for on-chain conditional orders
/// @author JaredBorders (jaredborders@pm.me)
contract OrderBook is EIP712, Ownable {
    using SignatureCheckerLib for bytes32;

    struct ConditionalOrder {
        // address of the signer of the order
        address signer;
        // an incrementing value indexed per order
        uint128 nonce;
        // option to require all extra conditions to be met
        bool requireVerified;
        // order market id.
        uint128 marketId;
        // order account id.
        uint128 accountId;
        // order size delta (of asset units expressed in decimal 18 digits). It can be positive or negative.
        int128 sizeDelta;
        // settlement strategy used for the order.
        uint128 settlementStrategyId;
        // acceptable price set at submission.
        uint256 acceptablePrice;
        // array of extra conditions to be met
        bytes[] conditions;
    }

    // pre-computed keccak256(ConditionalOrder struct)
    bytes32 private immutable CONDITIONAL_ORDER_TYPEHASH =
        0x97c4a1d00b5ee0ef549e3ea4b8c1d9330da4e4e9de51dcff8d243e587eedfd10;

    IPerpsMarketProxy public immutable PERPS_MARKET_PROXY;
    Engine public immutable ENGINE;
    mapping(uint128 nonce => bool) public executedOrders;

    constructor(address _owner, address _engine, address _perpsMarketProxy) {
        _initializeOwner(_owner);
        ENGINE = Engine(_engine);
        PERPS_MARKET_PROXY = IPerpsMarketProxy(_perpsMarketProxy);
    }

    function _domainNameAndVersion()
        internal
        pure
        override
        returns (string memory name, string memory version)
    {
        name = "SMv3: OrderBook";
        version = "1";
    }

    /*//////////////////////////////////////////////////////////////
                               EXECUTION
    //////////////////////////////////////////////////////////////*/

    error CannotExecuteOrder();

    function execute(ConditionalOrder calldata _co, bytes calldata _signature)
        external
    {
        uint256 gas = gasleft();

        if (!canExecute(_co, _signature)) revert CannotExecuteOrder();

        ENGINE.commitOrder(
            _co.marketId,
            _co.accountId,
            _co.sizeDelta,
            _co.settlementStrategyId,
            _co.acceptablePrice
        );

        uint256 gasSpent = gas - gasleft();

        /// @custom:todo determine the exchange rate for gas to sUSD
        /// @custom:todo deduct that from the account
        /// @custom:todo send sUSD to Kwenta Treasury
    }

    function canExecute(
        ConditionalOrder calldata _co,
        bytes calldata _signature
    ) public returns (bool) {
        if (!verifyAccountOwner(_co)) return false;

        if (!verifySignature(_signature, _co)) return false;

        if (_co.requireVerified && !verifyConditions(_co)) return false;

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                              VERIFICATION
    //////////////////////////////////////////////////////////////*/

    function verifyAccountOwner(ConditionalOrder calldata _co)
        public
        view
        returns (bool)
    {
        return PERPS_MARKET_PROXY.getAccountOwner(_co.accountId) == _co.signer;
    }

    function verifySignature(
        bytes calldata _signature,
        ConditionalOrder calldata _co
    ) public view returns (bool) {
        // prevent replay
        if (executedOrders[_co.nonce]) return false;

        // ensure signature is valid for signer and order
        bytes32 digest = _hashTypedData(
            keccak256(
                abi.encode(
                    CONDITIONAL_ORDER_TYPEHASH,
                    _co.signer,
                    _co.nonce,
                    _co.requireVerified,
                    _co.marketId,
                    _co.accountId,
                    _co.sizeDelta,
                    _co.settlementStrategyId,
                    _co.acceptablePrice,
                    _co.conditions
                )
            )
        );

        if (!digest.isValidSignatureNowCalldata(_signature, _co.signer)) {
            return false;
        }

        return true;
    }

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

    function isTimestampAfter(uint256 _timestamp) public view returns (bool) {
        return block.timestamp > _timestamp;
    }

    function isTimestampBefore(uint256 _timestamp) public view returns (bool) {
        return block.timestamp < _timestamp;
    }

    function isPriceAbove(uint256 price) public view returns (bool) {
        /// @custom:todo
    }

    function isPriceBelow(uint256 price) public view returns (bool) {
        /// @custom:todo
    }

    function isMarketPaused(address market) public view returns (bool) {
        /// @custom:todo
    }

    function isMarketClosed(address market) public view returns (bool) {
        /// @custom:todo
    }

    /// @custom:todo add more conditions
}

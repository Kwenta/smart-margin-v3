// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IEngine} from "src/interfaces/IEngine.sol";

/// @custom:todo add documentation
library ConditionalOrderHashLib {
    /// @notice pre-computed keccak256(OrderDetails struct)
    bytes32 public constant _ORDER_DETAILS_TYPEHASH = keccak256(
        "OrderDetails(uint128 marketId,uint128 accountId,int128 sizeDelta,uint128 settlementStrategyId,uint256 acceptablePrice)"
    );

    /// @notice pre-computed keccak256(ConditionalOrder struct)
    bytes32 public constant _CONDITIONAL_ORDER_TYPEHASH = keccak256(
        "ConditionalOrder(OrderDetails orderDetails,address signer,uint128 nonce,bool requireVerified,address trustedExecutor,bytes[] conditions)OrderDetails(uint128 marketId,uint128 accountId,int128 sizeDelta,uint128 settlementStrategyId,uint256 acceptablePrice)"
    );

    /// @custom:todo add documentation
    function hash(IEngine.OrderDetails memory orderDetails)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                _ORDER_DETAILS_TYPEHASH,
                orderDetails.marketId,
                orderDetails.accountId,
                orderDetails.sizeDelta,
                orderDetails.settlementStrategyId,
                orderDetails.acceptablePrice
            )
        );
    }

    /// @custom:todo add documentation
    function hash(IEngine.ConditionalOrder memory co)
        internal
        pure
        returns (bytes32)
    {
        bytes32 orderDetailsHash = hash(co.orderDetails);
        return keccak256(
            abi.encode(
                _CONDITIONAL_ORDER_TYPEHASH,
                orderDetailsHash,
                co.signer,
                co.nonce,
                co.requireVerified,
                co.trustedExecutor,
                co.conditions
            )
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {IEngine} from "src/interfaces/IEngine.sol";

/// @title Kwenta Smart Margin v3: Signature Hash Library for Conditional Orders
/// @notice Responsible for computing the hash of a Conditional Order
/// @author JaredBorders (jaredborders@pm.me)
library ConditionalOrderHashLib {
    /// @notice pre-computed keccak256(OrderDetails struct)
    bytes32 public constant _ORDER_DETAILS_TYPEHASH = keccak256(
        "OrderDetails(uint128 marketId,uint128 accountId,int128 sizeDelta,uint128 settlementStrategyId,uint256 acceptablePrice,bool isReduceOnly,bytes32 trackingCode,address referrer)"
    );

    /// @notice pre-computed keccak256(ConditionalOrder struct)
    bytes32 public constant _CONDITIONAL_ORDER_TYPEHASH = keccak256(
        "ConditionalOrder(OrderDetails orderDetails,address signer,uint256 nonce,bool requireVerified,address trustedExecutor,uint256 maxExecutorFee,bytes32 conditions)OrderDetails(uint128 marketId,uint128 accountId,int128 sizeDelta,uint128 settlementStrategyId,uint256 acceptablePrice,bool isReduceOnly,bytes32 trackingCode,address referrer)"
    );

    /// @notice hash the OrderDetails struct
    /// @param orderDetails OrderDetails struct
    /// @return hash of the OrderDetails struct
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
                orderDetails.acceptablePrice,
                orderDetails.isReduceOnly,
                orderDetails.trackingCode,
                orderDetails.referrer
            )
        );
    }

    /// @notice hash the ConditionalOrder struct
    /// @param co ConditionalOrder struct
    /// @return hash of the ConditionalOrder struct
    function hash(IEngine.ConditionalOrder memory co)
        internal
        pure
        returns (bytes32)
    {
        bytes32 orderDetailsHash = hash(co.orderDetails);

        // array of dynamic length bytes must be hashed separately
        // to create an array of fixed length bytes32 hashes
        bytes32[] memory hashedConditions;
        for (uint256 i = 0; i < co.conditions.length; i++) {
            hashedConditions[i] = keccak256(co.conditions[i]);
        }

        return keccak256(
            abi.encode(
                _CONDITIONAL_ORDER_TYPEHASH,
                orderDetailsHash,
                co.signer,
                co.nonce,
                co.requireVerified,
                co.trustedExecutor,
                co.maxExecutorFee,
                keccak256(abi.encode(hashedConditions))
            )
        );
    }
}

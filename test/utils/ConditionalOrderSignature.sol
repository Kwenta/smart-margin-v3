// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {IEngine} from "src/interfaces/IEngine.sol";
import {Vm} from "lib/forge-std/src/Vm.sol";

contract ConditionalOrderSignature {
    Vm private constant vm =
        Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    /// @notice pre-computed keccak256(OrderDetails struct)
    bytes32 public constant _ORDER_DETAILS_TYPEHASH = keccak256(
        "OrderDetails(uint128 marketId,uint128 accountId,int128 sizeDelta,uint128 settlementStrategyId,uint256 acceptablePrice,bool isReduceOnly,bytes32 trackingCode,address referrer)"
    );

    /// @notice pre-computed keccak256(ConditionalOrder struct)
    bytes32 public constant _CONDITIONAL_ORDER_TYPEHASH = keccak256(
        "ConditionalOrder(OrderDetails orderDetails,address signer,uint256 nonce,bool requireVerified,address trustedExecutor,uint256 maxExecutorFee,bytes[] conditions)OrderDetails(uint128 marketId,uint128 accountId,int128 sizeDelta,uint128 settlementStrategyId,uint256 acceptablePrice,bool isReduceOnly,bytes32 trackingCode,address referrer)"
    );

    function getConditionalOrderSignatureRaw(
        IEngine.ConditionalOrder memory co,
        uint256 privateKey,
        bytes32 domainSeparator
    ) internal returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 orderDetailsHash = keccak256(
            abi.encode(
                _ORDER_DETAILS_TYPEHASH,
                co.orderDetails.marketId,
                co.orderDetails.accountId,
                co.orderDetails.sizeDelta,
                co.orderDetails.settlementStrategyId,
                co.orderDetails.acceptablePrice,
                co.orderDetails.isReduceOnly,
                co.orderDetails.trackingCode,
                co.orderDetails.referrer
            )
        );

        // array of dynamic length bytes must be hashed separately
        // to create an array of fixed length bytes32 hashes
        bytes32[] memory hashedConditions;
        for (uint256 i = 0; i < co.conditions.length; i++) {
            hashedConditions[i] = keccak256(abi.encode(co.conditions[i]));
        }

        bytes32 conditionalOrderHash = keccak256(
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

        bytes32 msgHash = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, conditionalOrderHash)
        );

        (v, r, s) = vm.sign(privateKey, msgHash);
    }

    function getConditionalOrderSignature(
        IEngine.ConditionalOrder memory co,
        uint256 privateKey,
        bytes32 domainSeparator
    ) internal returns (bytes memory sig) {
        (uint8 v, bytes32 r, bytes32 s) =
            getConditionalOrderSignatureRaw(co, privateKey, domainSeparator);
        return bytes.concat(r, s, bytes1(v));
    }
}

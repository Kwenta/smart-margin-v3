// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Engine} from "src/Engine.sol";

contract Conditions {
    function isTimestampAfter(uint256 timestamp)
        public
        pure
        returns (bytes memory)
    {
        return
            abi.encodeWithSelector(Engine.isTimestampAfter.selector, timestamp);
    }

    function isTimestampBefore(uint256 timestamp)
        public
        pure
        returns (bytes memory)
    {
        return
            abi.encodeWithSelector(Engine.isTimestampBefore.selector, timestamp);
    }

    function isPriceAbove(
        bytes32 _assetId,
        int64 _price,
        uint64 _confidenceInterval
    ) public pure returns (bytes memory) {
        return abi.encodeWithSelector(
            Engine.isPriceAbove.selector, _assetId, _price, _confidenceInterval
        );
    }

    function isPriceBelow(
        bytes32 _assetId,
        int64 _price,
        uint64 _confidenceInterval
    ) public pure returns (bytes memory) {
        return abi.encodeWithSelector(
            Engine.isPriceBelow.selector, _assetId, _price, _confidenceInterval
        );
    }

    function isMarketOpen(uint128 _marketId)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(Engine.isMarketOpen.selector, _marketId);
    }
}

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

    function isPositionSizeAbove(
        uint128 _accountId,
        uint128 _marketId,
        int128 _size
    ) public pure returns (bytes memory) {
        return abi.encodeWithSelector(
            Engine.isPositionSizeAbove.selector, _accountId, _marketId, _size
        );
    }

    function isPositionSizeBelow(
        uint128 _accountId,
        uint128 _marketId,
        int128 _size
    ) public pure returns (bytes memory) {
        return abi.encodeWithSelector(
            Engine.isPositionSizeBelow.selector, _accountId, _marketId, _size
        );
    }

    function isOrderFeeBelow(uint128 _marketId, int128 _sizeDelta, uint256 _fee)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            Engine.isOrderFeeBelow.selector, _marketId, _sizeDelta, _fee
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {Engine} from "src/Engine.sol";

/// @title Contract for generating function signatures that define valid conditions
/// for conditional orders for testing purposes
/// @author JaredBorders (jaredborders@pm.me)
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

    function isPriceAbove(uint128 _marketId, uint256 _price)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            Engine.isPriceAbove.selector, _marketId, _price
        );
    }

    function isPriceBelow(uint128 _marketId, uint256 _price)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            Engine.isPriceBelow.selector, _marketId, _price
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

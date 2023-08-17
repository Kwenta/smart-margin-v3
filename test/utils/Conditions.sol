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
}

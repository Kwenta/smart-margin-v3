// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IPyth} from "src/interfaces/oracles/IPyth.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract PythMock is Test {
    function mock_pyth_getPrice(
        address pyth,
        bytes32 id,
        int64 price,
        uint64 conf,
        int32 expo
    ) public {
        vm.mockCall(
            pyth,
            abi.encodeWithSelector(IPyth.getPrice.selector, id),
            abi.encode(price, conf, expo, block.timestamp - 1)
        );
    }
}

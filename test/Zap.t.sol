// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {Bootstrap} from "test/utils/Bootstrap.sol";
import {IEngine} from "src/interfaces/IEngine.sol";

contract ZapTest is Bootstrap {
    function setUp() public {
        vm.rollFork(BASE_BLOCK_NUMBER);
        initializeBase();
    }

    function test_zap_NotSupported() public {
        vm.startPrank(ACTOR);

        vm.expectRevert(abi.encodeWithSelector(IEngine.NotSupported.selector));

        engine.zap(int256(AMOUNT), REFERRER);

        vm.stopPrank();
    }
}

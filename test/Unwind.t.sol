// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

import {Bootstrap, Engine} from "test/utils/Bootstrap.sol";
import {IEngine} from "src/interfaces/IEngine.sol";

contract UnwindTest is Bootstrap {
    function setUp() public {
        vm.rollFork(ARBITRUM_BLOCK_NUMBER);
        initializeArbitrum();
    }

    function test_unwindCollateral_UNAUTHORIZED() public {
        vm.expectRevert(abi.encodeWithSelector(IEngine.Unauthorized.selector));
        engine.unwindCollateral(accountId, 1, 1, address(0), 1, 1, 1, "");
    }

    function test_unwindCollateralETH_UNAUTHORIZED() public {
        vm.expectRevert(abi.encodeWithSelector(IEngine.Unauthorized.selector));
        engine.unwindCollateral(accountId, 1, 1, address(0), 1, 1, 1, "");
    }

    function test_unwindCollateral() public {
        // todo add test
        assertEq(true, false);
    }
}
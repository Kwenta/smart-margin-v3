// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Constants} from "test/utils/Constants.sol";
import {Stats, Ownable} from "src/modules/Stats.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract StatsTest is Test, Constants {
    Stats stats;

    function setUp() public {
        stats = new Stats(OWNER);
    }
}

contract StatsOwner is StatsTest {
    function test_owner() public {
        assertEq(stats.owner(), OWNER);
    }

    function test_transferOwnership() public {
        vm.prank(OWNER);

        stats.transferOwnership(ACTOR);

        assertEq(stats.owner(), ACTOR);
    }

    function test_transferOwnership_notOwner() public {
        vm.prank(BAD_ACTOR);

        vm.expectRevert(abi.encodeWithSelector(Ownable.Unauthorized.selector));

        stats.transferOwnership(ACTOR);
    }

    function test_transferOwnership_zeroAddress() public {
        vm.prank(OWNER);

        vm.expectRevert(
            abi.encodeWithSelector(Ownable.NewOwnerIsZeroAddress.selector)
        );

        stats.transferOwnership(address(0));
    }
}

contract RegisterMarginEngine is StatsTest {
    function test_registerMarginEngine() public {
        vm.prank(OWNER);

        stats.registerMarginEngine(MOCK_MARGIN_ENGINE);

        assertTrue(stats.registeredMarginEngines(MOCK_MARGIN_ENGINE));
    }

    function test_registerMarginEngine_notOwner() public {
        vm.prank(BAD_ACTOR);

        vm.expectRevert(abi.encodeWithSelector(Ownable.Unauthorized.selector));

        stats.registerMarginEngine(MOCK_MARGIN_ENGINE);
    }
}

contract UpdateAccountStats is StatsTest {
    uint128 accountId = 19;
    uint256 fees = 111;
    uint128 volume = 276;

    function test_updateAccountStats() public {
        vm.prank(OWNER);

        stats.registerMarginEngine(MOCK_MARGIN_ENGINE);

        vm.startPrank(MOCK_MARGIN_ENGINE);

        for (uint256 i = 1; i <= 10; i++) {
            stats.updateAccountStats(accountId, fees, volume);

            Stats.AccountStats memory accountStats =
                stats.getAccountStats(accountId);

            assertEq(accountStats.totalFees, fees * i);
            assertEq(accountStats.totalVolume, volume * i);
            assertEq(accountStats.totalTrades, i);
        }

        vm.stopPrank();
    }

    function test_updateAccountStats_notMarginEngine() public {
        vm.prank(BAD_ACTOR);

        vm.expectRevert(
            abi.encodeWithSelector(
                Stats.InvalidMarginEngine.selector, BAD_ACTOR
            )
        );

        stats.updateAccountStats(0, 0, 0);
    }
}

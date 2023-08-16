// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Constants} from "test/utils/Constants.sol";
import {IStats} from "src/modules/Stats.sol";
import {StatsExposed} from "test/utils/exposed/StatsExposed.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract StatsTest is Test, Constants {
    StatsExposed stats;

    function setUp() public {
        vm.rollFork(GOERLI_BLOCK_NUMBER);
        stats = new StatsExposed();
    }
}

contract UpdateAccountStats is StatsTest {
    function test_updateAccountStats(
        uint128 accountId,
        uint256 fees,
        uint128 volume
    ) public {
        vm.assume(fees < type(uint256).max / 10);
        vm.assume(volume < type(uint128).max / 10);

        for (uint256 i = 1; i <= 10; i++) {
            stats.updateAccountStats(accountId, fees, volume);

            IStats.AccountStats memory accountStats =
                stats.getAccountStats(accountId);

            assertEq(accountStats.totalFees, fees * i);
            assertEq(accountStats.totalVolume, volume * i);
            assertEq(accountStats.totalTrades, i);
        }
    }
}

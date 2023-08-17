// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Bootstrap} from "test/utils/Bootstrap.sol";
import {IEngine} from "src/interfaces/IEngine.sol";

contract StatsTest is Bootstrap {
    function setUp() public {
        vm.rollFork(GOERLI_BLOCK_NUMBER);
        initializeOptimismGoerli();
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
            engineExposed.updateAccountStats(accountId, fees, volume);

            IEngine.AccountStats memory accountStats =
                engineExposed.getAccountStats(accountId);

            assertEq(accountStats.totalFees, fees * i);
            assertEq(accountStats.totalVolume, volume * i);
            assertEq(accountStats.totalTrades, i);
        }
    }
}

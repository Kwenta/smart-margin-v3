// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Stats} from "src/modules/Stats.sol";

contract StatsExposed is Stats {
    function updateAccountStats(uint128 accountId, uint256 fees, uint128 volume)
        public
    {
        _updateAccountStats(accountId, fees, volume);
    }
}

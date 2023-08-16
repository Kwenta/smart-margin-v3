// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IStats} from "src/interfaces/modules/IStats.sol";

/// @title Kwenta Smart Margin v3: Stats Module
/// @notice Responsible for recording stats for accounts trading on verified margin engines
/// @author JaredBorders (jaredborders@pm.me)
contract Stats is IStats {
    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice mapping that stores stats for an account
    mapping(uint128 accountId => AccountStats) internal accountStats;

    /*//////////////////////////////////////////////////////////////
                                 STATS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IStats
    function getAccountStats(uint128 _accountId)
        external
        view
        returns (AccountStats memory)
    {
        return accountStats[_accountId];
    }

    /// @notice update the stats of an account
    /// @param _accountId the account to update
    /// @param _fees the fees to add to the account
    /// @param _volume the volume to add to the account
    /// @dev only callable by a validated margin engine
    function _updateAccountStats(
        uint128 _accountId,
        uint256 _fees,
        uint128 _volume
    ) internal {
        AccountStats storage stats = accountStats[_accountId];

        stats.totalFees += _fees;
        stats.totalVolume += _volume;
        stats.totalTrades++;
    }
}

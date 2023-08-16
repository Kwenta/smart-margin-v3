// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @title Kwenta Smart Margin v3: Stats Module Interface
/// @author JaredBorders (jaredborders@pm.me)
interface IStats {
    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/

    /// @notice stats for an account
    /// @custom:property totalFees the total fees paid by the account
    /// @custom:property totalVolume the total volume traded by the account
    /// @custom:property totalTrades the total number of trades made by the account
    struct AccountStats {
        uint256 totalFees;
        uint128 totalVolume;
        uint128 totalTrades;
    }

    /*//////////////////////////////////////////////////////////////
                                 STATS
    //////////////////////////////////////////////////////////////*/

    /// @notice get the stats for an account
    /// @param _accountId the account to get stats for
    /// @return stats the stats for the account
    function getAccountStats(uint128 _accountId)
        external
        view
        returns (AccountStats memory);
}

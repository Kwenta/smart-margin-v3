// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @title Kwenta Smart Margin v3: Authentication Module Interface
/// @author JaredBorders (jaredborders@pm.me)
interface IAuth {
    /*//////////////////////////////////////////////////////////////
                             AUTHENTICATION
    //////////////////////////////////////////////////////////////*/

    /// @notice check if the msg.sender is the owner of the account
    /// identified by the accountId
    /// @param _accountId the id of the account to check
    /// @return true if the msg.sender is the owner of the account
    function isAccountOwner(uint128 _accountId) external view returns (bool);

    /// @notice check if the msg.sender is a delegate of the account
    /// identified by the accountId
    /// @param _accountId the id of the account to check
    /// @return true if the msg.sender is a delegate of the account
    function isAccountDelegate(uint128 _accountId)
        external
        view
        returns (bool);
}

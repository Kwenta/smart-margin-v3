// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @title Kwenta Smart Margin v3: Constants Library
/// @author JaredBorders (jaredborders@pm.me)
library Constants {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice admins have permission to do everything that the account owner can
    /// (including granting and revoking permissions for other addresses) except
    /// for transferring account ownership
    bytes32 internal constant ADMIN_PERMISSION = "ADMIN";

    /// @notice the permission required to commit an async order
    /// @dev this permission does not allow the permission holder to modify collateral
    bytes32 internal constant PERPS_COMMIT_ASYNC_ORDER_PERMISSION =
        "PERPS_COMMIT_ASYNC_ORDER";

    /// @notice "0" synthMarketId represents sUSD in Synthetix v3
    uint128 internal constant USD_SYNTH_ID = 0;

    /// @notice max fee that can be charged for a conditional order execution
    /// @dev 50 USD
    uint256 internal constant UPPER_FEE_CAP = 50 ether;

    /// @notice min fee that can be charged for a conditional order execution
    /// @dev 2 USD
    uint256 internal constant LOWER_FEE_CAP = 2 ether;

    /// @notice percentage of the simulated order fee that is charged for a conditional order execution
    /// @dev denoted in BPS (basis points) where 1% = 100 BPS and 100% = 10000 BPS
    uint256 internal constant FEE_SCALING_FACTOR = 1000;

    /// @notice max BPS
    uint256 internal constant MAX_BPS = 10_000;

    /// @notice max number of conditions that can be defined for a conditional order
    uint256 internal constant MAX_CONDITIONS = 8;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

interface ICoreProxy {
    /// @notice calls Synthetix v3 core system to fetch
    /// the address of the USD token
    /// @return the address of the Synthetix v3 USD token
    function getUsdToken() external view returns (address);
}

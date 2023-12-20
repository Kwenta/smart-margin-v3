// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

contract OptimismGoerliParameters {
    /// @dev this is an EOA used on testnet only
    address public constant PDAO = 0x1b4fCFE451A15218aEeC811B508B4aa3f2A35904;

    address public constant PERPS_MARKET_PROXY =
        0xf272382cB3BE898A8CdB1A23BE056fA2Fcf4513b;

    address public constant SPOT_MARKET_PROXY =
        0x5FF4b3aacdeC86782d8c757FAa638d8790799E83;

    address public constant USD_PROXY =
        0xe487Ad4291019b33e2230F8E2FB1fb6490325260;
}

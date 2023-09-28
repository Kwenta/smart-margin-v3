// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

contract OptimismGoerliParameters {
    address public constant PERPS_MARKET_PROXY =
        0xf272382cB3BE898A8CdB1A23BE056fA2Fcf4513b;

    address public constant SPOT_MARKET_PROXY =
        0x5FF4b3aacdeC86782d8c757FAa638d8790799E83;

    address public constant USD_PROXY =
        0xe487Ad4291019b33e2230F8E2FB1fb6490325260;

    address public constant PYTH = 0xff1a0f4744e8582DF1aE09D5611b887B6a12925C;

    /// @custom:todo Optimism Goerli doesn't have a trusted forwarder yet
    address public constant TRUSTED_FORWARDER = 0xAE788aaf52780741E12BF79Ad684B91Bb0EF4D92;
}

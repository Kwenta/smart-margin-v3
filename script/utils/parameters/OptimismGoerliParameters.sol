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

    bytes32 public constant PYTH_ETH_USD_ID =
        0xca80ba6dc32e08d06f1aa886011eed1d77c77be9eb761cc10d72b7d0a2fd57a6;
}

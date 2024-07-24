// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

contract ArbitrumSepoliaParameters {
    address public constant PDAO = address(0);

    address public constant PERPS_MARKET_PROXY =
        0x111BAbcdd66b1B60A20152a2D3D06d36F8B5703c;

    address public constant SPOT_MARKET_PROXY =
        0x93d645c42A0CA3e08E9552367B8c454765fff041;

    address public constant USD_PROXY =
        0xe487Ad4291019b33e2230F8E2FB1fb6490325260;

    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    uint128 public constant SUSDC_SPOT_MARKET_ID = 1;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

contract ArbitrumSepoliaParameters {
    // Set to deployer key on testnet to perform testnet upgrades without multisig requirements
    address public constant PDAO = 0x88d40a3f2870e835005A3F1CFd28D94b12aD5483;

    address public constant PERPS_MARKET_PROXY =
        0xA73A7B754Ec870b3738D0654cA75b7d0eEbdb460;

    address public constant SPOT_MARKET_PROXY =
        0x93d645c42A0CA3e08E9552367B8c454765fff041;

    address public constant USD_PROXY =
        0xe487Ad4291019b33e2230F8E2FB1fb6490325260;

    address public constant USDC = 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d;

    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    address public constant ZAP = 0x5d13588285D8D8E612f3cd9803aaBfa2739C4Ec0;

    uint128 public constant SUSDC_SPOT_MARKET_ID = 2;
}

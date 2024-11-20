// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

contract BaseParameters {
    // Deployer base
    address public constant PDAO = 0x88d40a3f2870e835005A3F1CFd28D94b12aD5483;

    address public constant PERPS_MARKET_PROXY = address(0);

    address public constant SPOT_MARKET_PROXY = address(0);

    address public constant USD_PROXY = address(0);

    // https://usecannon.com/packages/synthetix-perps-market/3.3.5/8453-andromeda
    address public constant PERPS_MARKET_PROXY_ANDROMEDA =
        0x0A2AF931eFFd34b81ebcc57E3d3c9B1E1dE1C9Ce;

    // https://usecannon.com/packages/synthetix-spot-market/3.3.5/8453-andromeda
    address public constant SPOT_MARKET_PROXY_ANDROMEDA =
        0x18141523403e2595D31b22604AcB8Fc06a4CaA61;

    // https://usecannon.com/packages/synthetix/3.3.5/8453-andromeda
    address public constant USD_PROXY_ANDROMEDA =
        0x09d51516F38980035153a554c26Df3C6f51a23C3;

    // https://basescan.org/token/0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    address public constant WETH = 0x4200000000000000000000000000000000000006;

    // https://usecannon.com/packages/synthetix-spot-market/3.3.5/84531-andromeda
    uint128 public constant SUSDC_SPOT_MARKET_ID = 1;

    address public constant ZAP = 0xDE5858409c1776e03291242f2430413839Aaa35C;
}

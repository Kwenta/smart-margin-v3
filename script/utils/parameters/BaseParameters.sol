// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

contract BaseParameters {
    // https://app.safe.global/home?safe=base:0x2f4004Bc32cc5D18a62fE26E35A0881d5397c549
    address public constant PDAO = 0x2f4004Bc32cc5D18a62fE26E35A0881d5397c549;

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

    // https://usecannon.com/packages/synthetix-spot-market/3.3.5/84531-andromeda
    uint128 public constant SUSDC_SPOT_MARKET_ID = 1;
}

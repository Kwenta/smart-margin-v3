// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

contract BaseGoerliParameters {
    /// @dev this is an EOA used on testnet only
    address public constant PDAO = 0x1b4fCFE451A15218aEeC811B508B4aa3f2A35904;

    address public constant PERPS_MARKET_PROXY =
        0x9863Dae3f4b5F4Ffe3A841a21565d57F2BA10E87;

    address public constant SPOT_MARKET_PROXY =
        0x17633A63083dbd4941891F87Bdf31B896e91e2B9;

    address public constant USD_PROXY =
        0x579c612E4Bf390f5504DB9f76b6F5759A3172279;

    // https://usecannon.com/packages/synthetix-perps-market/3.3.5/84531-andromeda
    address public constant PERPS_MARKET_PROXY_ANDROMEDA =
        0x75c43165ea38cB857C45216a37C5405A7656673c;

    // https://usecannon.com/packages/synthetix-spot-market/3.3.5/84531-andromeda
    address public constant SPOT_MARKET_PROXY_ANDROMEDA =
        0x26f3EcFa0Aa924649cfd4b74C57637e910A983a4;

    // https://usecannon.com/packages/synthetix/3.3.5/84531-andromeda
    address public constant USD_PROXY_ANDROMEDA =
        0xa89163A087fe38022690C313b5D4BBF12574637f;

    // https://goerli.basescan.org/address/0x4967d1987930b2cd183dab4b6c40b8745dd2eba1
    address public constant USDC = 0x4967d1987930b2CD183dAB4B6C40B8745DD2eba1;

    // https://usecannon.com/packages/synthetix-spot-market/3.3.5/84531-andromeda
    uint128 public constant SUSDC_SPOT_MARKET_ID = 1;
}

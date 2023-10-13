// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

contract BaseGoerliParameters {
    address public constant PERPS_MARKET_PROXY =
        0x9863Dae3f4b5F4Ffe3A841a21565d57F2BA10E87;

    address public constant SPOT_MARKET_PROXY =
        0x17633A63083dbd4941891F87Bdf31B896e91e2B9;

    address public constant USD_PROXY =
        0x579c612E4Bf390f5504DB9f76b6F5759A3172279;

    address public constant PYTH = 0x5955C1478F0dAD753C7E2B4dD1b4bC530C64749f;

    address public constant TRUSTED_FORWARDER =
        0xAE788aaf52780741E12BF79Ad684B91Bb0EF4D92;
}
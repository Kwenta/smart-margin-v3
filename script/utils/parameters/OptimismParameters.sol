// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

contract OptimismParameters {
    address public constant PDAO = 0xe826d43961a87fBE71C91d9B73F7ef9b16721C07;

    address public constant PERPS_MARKET_PROXY = address(0);

    address public constant SPOT_MARKET_PROXY =
        0x38908Ee087D7db73A1Bd1ecab9AAb8E8c9C74595;

    address public constant USD_PROXY =
        0xb2F30A7C980f052f02563fb518dcc39e6bf38175;

    // https://optimistic.etherscan.io/token/0x0b2c639c533813f4aa9d7837caf62653d097ff85
    address public constant USDC = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;

    uint128 public constant SUSDC_SPOT_MARKET_ID = type(uint128).max;
}

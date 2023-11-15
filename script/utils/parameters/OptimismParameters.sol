// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

contract OptimismParameters {
    address public constant PERPS_MARKET_PROXY = address(0);

    address public constant SPOT_MARKET_PROXY =
        0x38908Ee087D7db73A1Bd1ecab9AAb8E8c9C74595;

    address public constant USD_PROXY =
        0xb2F30A7C980f052f02563fb518dcc39e6bf38175;

    address public constant PYTH = 0xff1a0f4744e8582DF1aE09D5611b887B6a12925C;
}

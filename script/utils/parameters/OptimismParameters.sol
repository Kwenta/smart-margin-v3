// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

// OPTIMISM_*

contract OptimismParameters {
    address constant PERPS_MARKET_PROXY = address(0);

    address constant SPOT_MARKET_PROXY =
        0x38908Ee087D7db73A1Bd1ecab9AAb8E8c9C74595;

    address constant USD_PROXY = 0xb2F30A7C980f052f02563fb518dcc39e6bf38175;

    address constant PYTH = 0xff1a0f4744e8582DF1aE09D5611b887B6a12925C;

    bytes32 constant PYTH_ETH_USD_ID =
        0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace;
}

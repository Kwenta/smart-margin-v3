// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

contract Constants {
    uint256 internal constant GOERLI_BLOCK_NUMBER = 13_995_234;

    address internal constant OWNER = address(0x01);

    bytes32 internal constant TRACKING_CODE = "KWENTA";

    address internal constant REFERRER =
        0xF510a2Ff7e9DD7e18629137adA4eb56B9c13E885;

    bytes32 internal constant ADMIN_PERMISSION = "ADMIN";

    address internal constant MOCK_MARGIN_ENGINE = address(0xE1);

    address internal constant ACTOR = address(0xa1);

    address internal constant BAD_ACTOR = address(0xa2);

    address internal constant NEW_ACTOR = address(0xa3);

    address internal constant DELEGATE_1 = address(0xd1);

    address internal constant DELEGATE_2 = address(0xd2);

    address internal constant DELEGATE_3 = address(0xd3);

    uint128 internal constant SUSD_SPOT_MARKET_ID = 0;

    uint128 internal constant SBTC_SPOT_MARKET_ID = 1;

    uint128 internal constant SETH_SPOT_MARKET_ID = 2;

    uint128 internal constant INVALID_PERPS_MARKET_ID = type(uint128).max;

    uint128 constant SETH_PERPS_MARKET_ID = 200;

    bytes32 constant PYTH_ETH_USD_ASSET_ID =
        0xca80ba6dc32e08d06f1aa886011eed1d77c77be9eb761cc10d72b7d0a2fd57a6;

    uint256 internal constant AMOUNT = 10_000 ether;

    address internal constant MARKET_CONFIGURATION_MODULE =
        0x1e1Bde584F428dE4a47865C5c07b2F5173cDcB10;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

/// @title Contract for defining constants used in testing
/// @author JaredBorders (jaredborders@pm.me)
contract Constants {
    uint256 public constant BASE_BLOCK_NUMBER = 8_163_300;

    address internal constant OWNER = address(0x01);

    bytes32 internal constant TRACKING_CODE = "KWENTA";

    address internal constant REFERRER = address(0xEFEFE);

    int128 internal constant SIZE_DELTA = 1 ether;

    int128 internal constant INVALID_SIZE_DELTA = type(int128).max;

    uint256 internal constant ACCEPTABLE_PRICE = type(uint256).max;

    uint256 internal constant INVALID_ACCEPTABLE_PRICE = 0;

    uint128 internal constant SETTLEMENT_STRATEGY_ID = 0;

    uint128 internal constant INVALID_SETTLEMENT_STRATEGY_ID = type(uint128).max;

    bytes32 internal constant ADMIN_PERMISSION = "ADMIN";

    bytes32 internal constant PERPS_COMMIT_ASYNC_ORDER_PERMISSION =
        "PERPS_COMMIT_ASYNC_ORDER";

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

    uint256 internal constant AMOUNT = 10_000 ether;

    address internal constant MARKET_CONFIGURATION_MODULE = address(0xC0FE);

    uint256 internal constant ZERO_CO_FEE = 0;

    uint256 internal constant CO_FEE = 620_198 wei;
}

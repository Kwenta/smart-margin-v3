// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

contract Constants {
    uint256 internal constant GOERLI_BLOCK_NUMBER = 14_862_158;

    address internal constant OWNER = address(0x01);

    bytes32 internal constant TRACKING_CODE = "KWENTA";

    address internal constant REFERRER =
        0xF510a2Ff7e9DD7e18629137adA4eb56B9c13E885;

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

    uint128 internal constant INVALID_PERPS_MARKET_ID = type(uint128).max;

    bytes32 constant PYTH_ETH_USD_ASSET_ID =
        0xca80ba6dc32e08d06f1aa886011eed1d77c77be9eb761cc10d72b7d0a2fd57a6;

    uint256 internal constant AMOUNT = 10_000 ether;

    address internal constant MARKET_CONFIGURATION_MODULE =
        0xE3b87A4c0E5F77504D6fa7656Cd8Caf2Ef331162;

    uint256 internal constant ZERO_CO_FEE = 0;

    uint256 internal constant CO_FEE = 100 wei;
}

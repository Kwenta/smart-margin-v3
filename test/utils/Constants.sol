// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

contract Constants {
    uint256 internal constant GOERLI_BLOCK_NUMBER = 13_076_019;

    address internal constant OWNER = address(0x01);
    address internal constant REFERRER =
        0x0a2578598C6Db6bc1C1FCE8aDcB1f52122940e05;

    bytes32 internal constant ADMIN_PERMISSION = "ADMIN";

    address internal constant MOCK_MARGIN_ENGINE = address(0xE1);

    address internal constant ACTOR = address(0xa1);
    address internal constant BAD_ACTOR = address(0xa2);
    address internal constant NEW_ACTOR = address(0xa3);

    address internal constant DELEGATE_1 = address(0xd1);
    address internal constant DELEGATE_2 = address(0xd2);
    address public constant DELEGATE_3 = address(0xd3);

    uint128 internal constant SUSD_SPOT_MARKET_ID = 0;
    uint128 internal constant SBTC_SPOT_MARKET_ID = 1;
    uint128 internal constant SETH_SPOT_MARKET_ID = 2;

    uint128 constant SETH_PERPS_MARKET_ID = 200;

    uint256 internal constant AMOUNT = 10_000 ether;
}

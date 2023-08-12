// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

contract Constants {
    uint256 public constant GOERLI_BLOCK_NUMBER = 13076019;

    address public constant OWNER = address(0x01);
    address public constant REFERRER = 0x0a2578598C6Db6bc1C1FCE8aDcB1f52122940e05;

    address public constant MOCK_MARGIN_ENGINE = address(0xE1);

    address public constant ACTOR = address(0xa1);
    address public constant BAD_ACTOR = address(0xa2);
    address public constant NEW_ACTOR = address(0xa3);

    address public constant DELEGATE_1 = address(0xd1);
    address public constant DELEGATE_2 = address(0xd2);
    address public constant DELEGATE_3 = address(0xd3);

    uint128 constant SUSD_SPOT_MARKET_ID = 0;
    uint128 constant SBTC_SPOT_MARKET_ID = 1;
    uint128 constant SETH_SPOT_MARKET_ID = 2;

    uint128 constant SETH_PERPS_MARKET_ID = 200;

    uint256 public constant AMOUNT = 10_000 ether;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

contract BaseSepoliaParameters {
    /// @dev this is an EOA used on testnet only
    address public constant PDAO = 0x1b4fCFE451A15218aEeC811B508B4aa3f2A35904;

    address public constant PERPS_MARKET_PROXY = address(0);

    address public constant SPOT_MARKET_PROXY = address(0);

    address public constant USD_PROXY = address(0);

    // https://usecannon.com/packages/synthetix-perps-market/3.3.5/84532-andromeda/
    address public constant PERPS_MARKET_PROXY_ANDROMEDA =
        0xE6C5f05C415126E6b81FCc3619f65Db2fCAd58D0;

    // https://usecannon.com/packages/synthetix-perps-market/3.3.5/84532-andromeda/
    address public constant SPOT_MARKET_PROXY_ANDROMEDA =
        0xA4fE63F8ea9657990eA8E05Ebfa5C19a7D4d7337;

    // https://usecannon.com/packages/synthetix-perps-market/3.3.5/84532-andromeda/
    address public constant USD_PROXY_ANDROMEDA =
        0xa89163A087fe38022690C313b5D4BBF12574637f;

    // https://base-sepolia.blockscout.com/address/0x69980C3296416820623b3e3b30703A74e2320bC8
    address public constant USDC = 0x69980C3296416820623b3e3b30703A74e2320bC8;

    // https://usecannon.com/packages/synthetix-spot-market/3.3.5/84531-andromeda
    uint128 public constant SUSDC_SPOT_MARKET_ID = 1;
}

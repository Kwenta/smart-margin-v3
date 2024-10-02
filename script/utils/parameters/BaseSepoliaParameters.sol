// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

contract BaseSepoliaParameters {
    /// @dev this is an EOA used on testnet only
    address public constant PDAO = 0x12d970154Ac171293323f20757130d5731850deB;

    address public constant PERPS_MARKET_PROXY = address(0);

    address public constant SPOT_MARKET_PROXY = address(0);

    address public constant USD_PROXY = address(0);

    // https://usecannon.com/packages/synthetix-perps-market/3.3.5/84532-andromeda/
    address public constant PERPS_MARKET_PROXY_ANDROMEDA =
        0xf53Ca60F031FAf0E347D44FbaA4870da68250c8d;

    // https://usecannon.com/packages/synthetix-perps-market/3.3.5/84532-andromeda/
    address public constant SPOT_MARKET_PROXY_ANDROMEDA =
        0xaD2fE7cd224c58871f541DAE01202F93928FEF72;

    // https://usecannon.com/packages/synthetix-perps-market/3.3.5/84532-andromeda/
    address public constant USD_PROXY_ANDROMEDA =
        0x682f0d17feDC62b2a0B91f8992243Bf44cAfeaaE;

    // https://base-sepolia.blockscout.com/address/0x69980C3296416820623b3e3b30703A74e2320bC8
    address public constant USDC = 0x69980C3296416820623b3e3b30703A74e2320bC8;

    // https://usecannon.com/packages/synthetix-spot-market/3.3.5/84531-andromeda
    uint128 public constant SUSDC_SPOT_MARKET_ID = 1;
}

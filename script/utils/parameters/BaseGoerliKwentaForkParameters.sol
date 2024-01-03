// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

contract BaseGoerliKwentaForkParameters {
    /// @dev this is an EOA used on testnet only
    address public constant PDAO = 0x1b4fCFE451A15218aEeC811B508B4aa3f2A35904;

    address public constant PERPS_MARKET_PROXY =
        0x5D48528E90EDEFA8cff2A23E1e3fda46Acef0E2d;

    address public constant SPOT_MARKET_PROXY =
        0xB462f8FC435fD78E16C0287fDBF706BcE87076be;

    address public constant USD_PROXY =
        0xD3bcDae94B0c2EF16d1c43d29c23b1735d864fC6;

    // https://developers.circle.com/stablecoins/docs/usdc-on-test-networks#usdc-on-base-goerli
    address public constant USDC = 0xF175520C52418dfE19C8098071a252da48Cd1C19;

    uint128 public constant SUSDC_SPOT_MARKET_ID = type(uint128).max;
}

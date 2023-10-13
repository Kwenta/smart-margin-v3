// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

contract BaseParameters {
    address public constant PERPS_MARKET_PROXY = address(0);

    address public constant SPOT_MARKET_PROXY = address(0);

    address public constant USD_PROXY = address(0);

    address public constant PYTH = 0x8250f4aF4B972684F7b336503E2D6dFeDeB1487a;

    /// @custom:todo Base doesn't have a trusted forwarder yet
    address public constant TRUSTED_FORWARDER = address(0);
}
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {Engine, MathLib} from "src/Engine.sol";

/// @title Contract for exposing internal Engine functions for testing purposes
/// @author JaredBorders (jaredborders@pm.me)
contract EngineExposed is Engine {
    using MathLib for uint256;

    constructor(
        address _perpsMarketProxy,
        address _spotMarketProxy,
        address _sUSDProxy
    ) Engine(_perpsMarketProxy, _spotMarketProxy, _sUSDProxy) {}

    function getSynthAddress(uint128 synthMarketId)
        public
        view
        returns (address)
    {
        return _getSynthAddress(synthMarketId);
    }
}

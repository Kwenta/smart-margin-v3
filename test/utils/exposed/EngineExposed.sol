// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Engine, MathLib} from "src/Engine.sol";

contract EngineExposed is Engine {
    using MathLib for uint256;

    constructor(
        address _perpsMarketProxy,
        address _spotMarketProxy,
        address _sUSDProxy,
        address _oracle
    ) Engine(_perpsMarketProxy, _spotMarketProxy, _sUSDProxy, _oracle) {}

    function getSynthAddress(uint128 synthMarketId)
        public
        view
        returns (address)
    {
        return _getSynthAddress(synthMarketId);
    }

    function expose_UPPER_FEE_CAP() public pure returns (uint256) {
        return UPPER_FEE_CAP;
    }

    function expose_LOWER_FEE_CAP() public pure returns (uint256) {
        return LOWER_FEE_CAP;
    }

    function expose_FEE_SCALING_FACTOR() public pure returns (uint256) {
        return FEE_SCALING_FACTOR;
    }

    function expose_MAX_BPS() public pure returns (uint256) {
        return MAX_BPS;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Engine, Constants, MathLib} from "src/Engine.sol";

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

    function UPPER_FEE_CAP() public pure returns (uint256) {
        return Constants.UPPER_FEE_CAP;
    }

    function LOWER_FEE_CAP() public pure returns (uint256) {
        return Constants.LOWER_FEE_CAP;
    }

    function FEE_SCALING_FACTOR() public pure returns (uint256) {
        return Constants.FEE_SCALING_FACTOR;
    }

    function MAX_BPS() public pure returns (uint256) {
        return Constants.MAX_BPS;
    }
}

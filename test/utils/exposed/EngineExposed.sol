// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {Engine} from "src/Engine.sol";

/// @title Contract for exposing internal Engine functions for testing purposes
/// @author JaredBorders (jaredborders@pm.me)
contract EngineExposed is Engine {
    constructor(
        address _perpsMarketProxy,
        address _spotMarketProxy,
        address _sUSDProxy,
        address _pDAO,
        address _usdc,
        uint128 _sUSDCId
    )
        Engine(
            _perpsMarketProxy,
            _spotMarketProxy,
            _sUSDProxy,
            _pDAO,
            _usdc,
            _sUSDCId
        )
    {}

    function getSynthAddress(uint128 synthMarketId)
        public
        view
        returns (address)
    {
        return _getSynthAddress(synthMarketId);
    }

    function getNonceBitmapSlot() public pure returns (uint256 slot) {
        assembly {
            slot := nonceBitmap.slot
        }
    }

    function getCreditSlot() public pure returns (uint256 slot) {
        assembly {
            slot := credit.slot
        }
    }
}

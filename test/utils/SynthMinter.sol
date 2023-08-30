// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Constants} from "test/utils/Constants.sol";
import {IERC20} from "src/interfaces/tokens/IERC20.sol";
import {ISpotMarketProxy} from "src/interfaces/synthetix/ISpotMarketProxy.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract SynthMinter is Test, Constants {
    address public immutable sUSD;
    IERC20 public immutable sBTC;
    ISpotMarketProxy public immutable spotMarketProxy;

    constructor(address _sUSDAddress, address _spotMarketProxy) {
        sUSD = _sUSDAddress;
        spotMarketProxy = ISpotMarketProxy(_spotMarketProxy);
        sBTC = IERC20(
            ISpotMarketProxy(spotMarketProxy).getSynth(SBTC_SPOT_MARKET_ID)
        );
    }

    function mint_sUSD(address target, uint256 amount) public {
        deal(sUSD, target, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {Constants} from "test/utils/Constants.sol";
import {ISpotMarketProxy} from "src/interfaces/synthetix/ISpotMarketProxy.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract SynthMinter is Test, Constants {
    address public immutable sUSD;
    ISpotMarketProxy public immutable spotMarketProxy;

    constructor(address _sUSDAddress, address _spotMarketProxy) {
        sUSD = _sUSDAddress;
        spotMarketProxy = ISpotMarketProxy(_spotMarketProxy);
    }

    function mint_sUSD(address target, uint256 amount) public {
        deal(sUSD, target, amount);
    }
}

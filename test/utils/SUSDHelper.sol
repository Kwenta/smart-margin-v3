// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Constants} from "test/utils/Constants.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract SUSDHelper is Test, Constants {
    address sUSD;

    constructor(address _sUSDAddress) {
        sUSD = _sUSDAddress;
    }

    function mint(address target, uint256 amount) public {
        deal(sUSD, target, amount);
    }
}

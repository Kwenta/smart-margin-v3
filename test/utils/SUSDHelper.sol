// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IERC20} from "src/interfaces/tokens/IERC20.sol";
import {OPTIMISM_GOERLI_SUSD_PROXY} from
    "script/utils/parameters/OptimismGoerliParameters.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract SUSDHelper is Test {
    address constant sUSD = OPTIMISM_GOERLI_SUSD_PROXY;

    function mint(address target, uint256 amount) public {
        deal(sUSD, target, amount);
    }
}

contract Mint is SUSDHelper {
    function test_mint() public {
        mint(address(this), 1000 ether);
        uint256 balance = IERC20(sUSD).balanceOf(address(this));
        assertEq(balance, 1000 ether);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Constants} from "test/utils/Constants.sol";
import {IERC20} from "src/interfaces/tokens/IERC20.sol";
import {OptimismGoerliParameters} from "script/Deploy.s.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract SUSDHelper is Test, Constants, OptimismGoerliParameters {
    function mint(address target, uint256 amount) public {
        deal(OPTIMISM_GOERLI_USD_PROXY, target, amount);
    }
}

contract Mint is SUSDHelper {
    function test_mint() public {
        mint(address(this), AMOUNT);
        IERC20 sUSD = IERC20(OPTIMISM_GOERLI_USD_PROXY);
        uint256 balance = sUSD.balanceOf(address(this));
        assertEq(balance, AMOUNT);
    }
}

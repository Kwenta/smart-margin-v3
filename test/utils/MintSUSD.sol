// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IERC20} from "lib/synthetix-v3/utils/core-contracts/contracts/interfaces/IERC20.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract MintSUSD is Test {
    address snxUSD = 0xe487Ad4291019b33e2230F8E2FB1fb6490325260;

    function mint(address target, uint256 amount) public {
        deal(snxUSD, target, amount);
    }
}

contract TestMint is MintSUSD {
    function test_mint() public {
        mint(address(this), 1000 ether);
        uint balance = IERC20(snxUSD).balanceOf(address(this));
        assertEq(balance, 1000 ether);
    }
}

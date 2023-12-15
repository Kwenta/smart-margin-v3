// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {Bootstrap} from "test/utils/Bootstrap.sol";

contract CreditTest is Bootstrap {
    function setUp() public {
        vm.rollFork(GOERLI_BLOCK_NUMBER);
        initializeOptimismGoerli();
    }
}

contract Deposit is CreditTest {
    function test_deposit(uint256 amount) public {
        assert(true);
    }
}

contract Withdraw is CreditTest {
    function test_withdraw(uint256 amount) public {
        assert(true);
    }
}

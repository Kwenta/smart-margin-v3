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
        // amount 0
        // amount exceeds callers balance
        // 0 < amount <= callers balance
        assert(false);
    }

    function test_deposit_AccountDoesNotExist() public {
        assert(false);
    }

    function test_deposit_event() public {
        assert(false);
    }
}

contract Withdraw is CreditTest {
    function test_withdraw(uint256 amount) public {
        // amount 0
        // amount exceeds account's credit
        // 0 < amount <= account's credit
        assert(false);
    }

    function test_withdraw_Unauthorized() public {
        assert(false);
    }

    function test_withdraw_event() public {
        assert(false);
    }

    function test_withdraw_InsufficientBalance() public {
        assert(false);
    }

    function test_withdraw_transfer_fails() public {
        assert(false);
    }
}

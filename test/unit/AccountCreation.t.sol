// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Bootstrap} from "test/utils/Bootstrap.sol";

contract AccountCreationTest is Bootstrap {
    function setUp() public {
        vm.rollFork(GOERLI_BLOCK_NUMBER);
        initializeOptimismGoerli();
    }
}

contract CreateAccount is AccountCreationTest {
    function test_createAccount() public {
        vm.prank(ACTOR);

        engine.createAccount();

        /// @custom:todo check that ACTOR is now the owner of the account
    }
}

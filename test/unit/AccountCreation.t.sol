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

        uint128 accountId = engine.createAccount();

        // accountId should be non-zero at this block; but theoretically it could be zero.
        // However, if it is non-zero, that affirms that the account was created.
        assert(accountId != 0);
    }

    function test_createAccount_owner() public {
        vm.prank(ACTOR);

        uint128 accountId = engine.createAccount();

        assertEq(perpsMarketProxy.getAccountOwner(accountId), ACTOR);
    }

    function test_createAccount_permissions() public {
        vm.prank(ACTOR);

        uint128 accountId = engine.createAccount();

        perpsMarketProxy.hasPermission(
            accountId, ADMIN_PERMISSION, address(engine)
        );
    }
}

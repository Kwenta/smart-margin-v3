// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Bootstrap} from "test/utils/Bootstrap.sol";

contract AuthenticationTest is Bootstrap {
    function setUp() public {
        vm.rollFork(GOERLI_BLOCK_NUMBER);
        initializeOptimismGoerli();
    }
}

contract AccountOwner is AuthenticationTest {
    function test_isAccountOwner_true() public {
        vm.prank(ACTOR);

        uint128 accountId = perpsMarketProxy.createAccount();

        bool isOwner = engine.isAccountOwner(accountId, ACTOR);

        assertTrue(isOwner);
    }

    function test_isAccountOwner_false() public {
        vm.prank(ACTOR);

        uint128 accountId = perpsMarketProxy.createAccount();

        bool isOwner = engine.isAccountOwner(accountId, BAD_ACTOR);

        assertFalse(isOwner);
    }
}

contract AccountDelegate is AuthenticationTest {
    function test_isAccountDelegate_true() public {
        vm.startPrank(ACTOR);

        uint128 accountId = perpsMarketProxy.createAccount();

        perpsMarketProxy.grantPermission({
            accountId: accountId,
            permission: "ADMIN",
            user: NEW_ACTOR
        });

        vm.stopPrank();

        bool isDelegate = engine.isAccountDelegate(accountId, NEW_ACTOR);

        assertTrue(isDelegate);
    }

    function test_isAccountDelegate_false() public {
        vm.startPrank(ACTOR);

        uint128 accountId = perpsMarketProxy.createAccount();

        perpsMarketProxy.grantPermission({
            accountId: accountId,
            permission: "ADMIN",
            user: NEW_ACTOR
        });

        vm.stopPrank();

        bool isDelegate = engine.isAccountDelegate(accountId, BAD_ACTOR);

        assertFalse(isDelegate);
    }
}

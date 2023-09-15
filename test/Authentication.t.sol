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

    function test_isAccountOwner_account_doesnt_exist() public {
        uint128 accountId = type(uint128).max;

        address owner = perpsMarketProxy.getAccountOwner(accountId);

        assertTrue(owner == address(0));

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
            permission: PERPS_COMMIT_ASYNC_ORDER_PERMISSION,
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
            permission: PERPS_COMMIT_ASYNC_ORDER_PERMISSION,
            user: NEW_ACTOR
        });

        vm.stopPrank();

        bool isDelegate = engine.isAccountDelegate(accountId, BAD_ACTOR);

        assertFalse(isDelegate);
    }

    function test_isAccountDelegate_account_doesnt_exist() public {
        uint128 accountId = type(uint128).max;

        address owner = perpsMarketProxy.getAccountOwner(accountId);

        assertTrue(owner == address(0));

        vm.prank(ACTOR);

        vm.expectRevert(
            abi.encodeWithSelector(
                PermissionDenied.selector, accountId, ADMIN_PERMISSION, ACTOR
            )
        );

        // only admin and owner can grant permission
        
        perpsMarketProxy.grantPermission({
            accountId: accountId,
            permission: PERPS_COMMIT_ASYNC_ORDER_PERMISSION,
            user: NEW_ACTOR
        });
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Auth} from "src/authentication/Auth.sol";
import {OPTIMISM_GOERLI_PERPS_MARKET_PROXY} from
    "script/utils/parameters/OptimismGoerliParameters.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract AuthenticationTest is Test {
    Auth auth;

    function setUp() public {
        vm.rollFork(13_006_356);

        auth = new Auth(OPTIMISM_GOERLI_PERPS_MARKET_PROXY);
    }
}

contract CreateAccount is AuthenticationTest {
    function test_CreateAccount() public {
        uint128 accountId = auth.createAccount();
        assert(accountId != 0);
    }
}

contract AccountOwnership is AuthenticationTest {
    address owner = address(0x1);
    address badActor = address(0x2);

    function test_isActorAccountOwner() public {
        vm.startPrank(owner);

        uint128 accountId = auth.createAccount();

        bool isOwner = auth.isActorAccountOwner(owner, accountId);
        assertTrue(isOwner);

        vm.stopPrank();
    }

    function test_getOwnerByAccountId() public {
        vm.prank(owner);
        uint128 accountId = auth.createAccount();

        assertEq(auth.getOwnerByAccountId(accountId), owner);
    }

    function test_accountIdsByOwner() public {
        vm.prank(owner);
        uint128 accountId = auth.createAccount();

        uint128[] memory accountIds = auth.getAccountIdsByOwner(owner);
        assertEq(accountIds.length, 1);
        assertEq(accountIds[0], accountId);
    }

    function test_transferOwnership() public {
        address newOwner = address(0x2);

        vm.startPrank(owner);

        uint128 accountId = auth.createAccount();

        auth.transferOwnership(accountId, newOwner);

        vm.stopPrank();

        vm.startPrank(newOwner);

        bool isOwner = auth.isActorAccountOwner(newOwner, accountId);
        assertTrue(isOwner);

        vm.stopPrank();
    }

    function test_transferOwnership_OnlyOwner() public {
        vm.prank(owner);

        uint128 accountId = auth.createAccount();

        vm.prank(badActor);

        vm.expectRevert(
            abi.encodeWithSelector(
                Auth.OnlyAccountOwner.selector, accountId, badActor
            )
        );
        auth.transferOwnership(accountId, badActor);
    }

    function test_transferOwnership_ownerByAccountId() public {
        address newOwner = address(0x2);

        vm.startPrank(owner);

        uint128 accountId = auth.createAccount();

        auth.transferOwnership(accountId, newOwner);

        vm.stopPrank();

        assertEq(auth.getOwnerByAccountId(accountId), newOwner);
    }

    function test_transferOwnership_accountIdsByOwner() public {
        address newOwner = address(0x2);

        vm.startPrank(owner);

        uint128 accountId = auth.createAccount();

        auth.transferOwnership(accountId, newOwner);

        vm.stopPrank();

        uint128[] memory accountIds = auth.getAccountIdsByOwner(owner);
        assertEq(accountIds.length, 0);

        accountIds = auth.getAccountIdsByOwner(newOwner);
        assertEq(accountIds.length, 1);
        assertEq(accountIds[0], accountId);
    }
}

contract Delegation is AuthenticationTest {
    address owner = address(0x1);
    address badActor = address(0x2);

    address delegate1 = address(0x3);
    address delegate2 = address(0x4);
    address delegate3 = address(0x5);

    uint128 accountId1;
    uint128 accountId2;
    uint128 accountId3;

    function test_isActorDelegate() public {
        vm.startPrank(owner);

        accountId1 = auth.createAccount();

        auth.addDelegate(accountId1, delegate1);
        auth.addDelegate(accountId1, delegate2);
        auth.addDelegate(accountId1, delegate3);

        vm.stopPrank();

        bool isDelegate;

        isDelegate = auth.isActorDelegate(delegate1, accountId1);
        assertTrue(isDelegate);

        isDelegate = auth.isActorDelegate(delegate2, accountId1);
        assertTrue(isDelegate);

        isDelegate = auth.isActorDelegate(delegate3, accountId1);
        assertTrue(isDelegate);
    }

    function test_isActorDelegate_OnlyOwner() public {
        vm.prank(owner);

        accountId1 = auth.createAccount();

        vm.prank(badActor);

        vm.expectRevert(
            abi.encodeWithSelector(
                Auth.OnlyAccountOwner.selector, accountId1, badActor
            )
        );

        auth.addDelegate(accountId1, delegate1);
    }

    function test_getDelegatesByAccountId() public {
        vm.startPrank(owner);

        accountId1 = auth.createAccount();

        auth.addDelegate(accountId1, delegate1);
        auth.addDelegate(accountId1, delegate2);
        auth.addDelegate(accountId1, delegate3);

        vm.stopPrank();

        address[] memory delegates;

        delegates = auth.getDelegatesByAccountId(accountId1);
        assertEq(delegates.length, 3);
        assertEq(delegates[0], delegate1);
        assertEq(delegates[1], delegate2);
        assertEq(delegates[2], delegate3);
    }

    function test_getAccountIdsByDelegate() public {
        vm.startPrank(owner);

        accountId1 = auth.createAccount();
        accountId2 = auth.createAccount();
        accountId3 = auth.createAccount();

        auth.addDelegate(accountId1, delegate1);
        auth.addDelegate(accountId2, delegate1);
        auth.addDelegate(accountId3, delegate1);

        vm.stopPrank();

        uint128[] memory accountIds;

        accountIds = auth.getAccountIdsByDelegate(delegate1);
        assertEq(accountIds.length, 3);
        assertEq(accountIds[0], accountId1);
        assertEq(accountIds[1], accountId2);
        assertEq(accountIds[2], accountId3);
    }

    function test_removeDelegate() public {
        vm.startPrank(owner);

        accountId1 = auth.createAccount();

        auth.addDelegate(accountId1, delegate1);
        auth.addDelegate(accountId1, delegate2);
        auth.addDelegate(accountId1, delegate3);

        auth.removeDelegate(accountId1, delegate2);

        vm.stopPrank();

        bool isDelegate;

        isDelegate = auth.isActorDelegate(delegate1, accountId1);
        assertTrue(isDelegate);

        isDelegate = auth.isActorDelegate(delegate2, accountId1);
        assertFalse(isDelegate);

        isDelegate = auth.isActorDelegate(delegate3, accountId1);
        assertTrue(isDelegate);
    }

    function test_removeDelegate_OnlyOwner() public {
        vm.startPrank(owner);

        accountId1 = auth.createAccount();

        auth.addDelegate(accountId1, delegate1);

        vm.stopPrank();

        vm.prank(badActor);

        vm.expectRevert(
            abi.encodeWithSelector(
                Auth.OnlyAccountOwner.selector, accountId1, badActor
            )
        );

        auth.removeDelegate(accountId1, delegate1);
    }

    function test_removeDelegate_delegatesByAccountId() public {
        vm.startPrank(owner);

        accountId1 = auth.createAccount();

        auth.addDelegate(accountId1, delegate1);
        auth.addDelegate(accountId1, delegate2);
        auth.addDelegate(accountId1, delegate3);

        auth.removeDelegate(accountId1, delegate2);

        vm.stopPrank();

        address[] memory delegates;

        delegates = auth.getDelegatesByAccountId(accountId1);
        assertEq(delegates.length, 2);
        assertEq(delegates[0], delegate1);
        assertEq(delegates[1], delegate3);
    }

    function test_removeDelegate_accountIdsByDelegate() public {
        vm.startPrank(owner);

        accountId1 = auth.createAccount();
        accountId2 = auth.createAccount();
        accountId3 = auth.createAccount();

        auth.addDelegate(accountId1, delegate1);
        auth.addDelegate(accountId2, delegate1);
        auth.addDelegate(accountId3, delegate1);

        auth.removeDelegate(accountId2, delegate1);

        vm.stopPrank();

        uint128[] memory accountIds;

        accountIds = auth.getAccountIdsByDelegate(delegate1);
        assertEq(accountIds.length, 2);
        assertEq(accountIds[0], accountId1);
        assertEq(accountIds[1], accountId3);
    }

    function test_removeDelegate_All_Delegates() public {
        vm.startPrank(owner);

        accountId1 = auth.createAccount();

        auth.addDelegate(accountId1, delegate1);
        auth.addDelegate(accountId1, delegate2);
        auth.addDelegate(accountId1, delegate3);

        auth.removeDelegate(accountId1, delegate1);
        auth.removeDelegate(accountId1, delegate2);
        auth.removeDelegate(accountId1, delegate3);

        vm.stopPrank();

        bool isDelegate;

        isDelegate = auth.isActorDelegate(delegate1, accountId1);
        assertFalse(isDelegate);

        isDelegate = auth.isActorDelegate(delegate2, accountId1);
        assertFalse(isDelegate);

        isDelegate = auth.isActorDelegate(delegate3, accountId1);
        assertFalse(isDelegate);

        address[] memory delegates;

        delegates = auth.getDelegatesByAccountId(accountId1);
        assertEq(delegates.length, 0);

        uint128[] memory accountIds;

        accountIds = auth.getAccountIdsByDelegate(delegate1);
        assertEq(accountIds.length, 0);

        accountIds = auth.getAccountIdsByDelegate(delegate2);
        assertEq(accountIds.length, 0);

        accountIds = auth.getAccountIdsByDelegate(delegate3);
        assertEq(accountIds.length, 0);
    }

    function test_removeDelegate_From_AccountIds() public {
        vm.startPrank(owner);

        accountId1 = auth.createAccount();
        accountId2 = auth.createAccount();
        accountId3 = auth.createAccount();

        auth.addDelegate(accountId1, delegate1);
        auth.addDelegate(accountId2, delegate1);
        auth.addDelegate(accountId3, delegate1);

        auth.removeDelegate(accountId1, delegate1);
        auth.removeDelegate(accountId2, delegate1);
        auth.removeDelegate(accountId3, delegate1);

        vm.stopPrank();

        bool isDelegate;

        isDelegate = auth.isActorDelegate(delegate1, accountId1);
        assertFalse(isDelegate);

        isDelegate = auth.isActorDelegate(delegate1, accountId2);
        assertFalse(isDelegate);

        isDelegate = auth.isActorDelegate(delegate1, accountId3);
        assertFalse(isDelegate);

        address[] memory delegates;

        delegates = auth.getDelegatesByAccountId(accountId1);
        assertEq(delegates.length, 0);

        delegates = auth.getDelegatesByAccountId(accountId2);
        assertEq(delegates.length, 0);

        delegates = auth.getDelegatesByAccountId(accountId3);
        assertEq(delegates.length, 0);

        uint128[] memory accountIds;

        accountIds = auth.getAccountIdsByDelegate(delegate1);
        assertEq(accountIds.length, 0);
    }

    function test_removeDelegate_None_Existent() public {
        vm.startPrank(owner);

        accountId1 = auth.createAccount();

        assertFalse(auth.isActorDelegate(delegate1, accountId1));

        // no-op if delegate doesn't exist for account
        auth.removeDelegate(accountId1, delegate1);

        assertFalse(auth.isActorDelegate(delegate1, accountId1));

        vm.stopPrank();
    }

    function test_removeDelegate_Twice() public {
        vm.startPrank(owner);

        accountId1 = auth.createAccount();

        auth.addDelegate(accountId1, delegate1);

        auth.removeDelegate(accountId1, delegate1);

        // no-op if delegate doesn't exist for account
        auth.removeDelegate(accountId1, delegate1);

        assertFalse(auth.isActorDelegate(delegate1, accountId1));

        vm.stopPrank();
    }
}

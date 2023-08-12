// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Auth} from "src/modules/Auth.sol";
import {Constants} from "test/utils/Constants.sol";
import {OPTIMISM_GOERLI_PERPS_MARKET_PROXY} from
    "script/utils/parameters/OptimismGoerliParameters.sol";
import {Test} from "lib/forge-std/src/Test.sol";

/// @custom:todo make sure tests are named correctly/consistently

contract AuthTest is Test, Constants {
    Auth auth;

    function setUp() public {
        vm.rollFork(13_149_245);

        auth = new Auth(OPTIMISM_GOERLI_PERPS_MARKET_PROXY);
    }
}

contract AccountManagement is AuthTest {
    uint128 accountId;

    function test_createAccount() public {
        vm.prank(ACTOR);
        accountId = auth.createAccount();
        assert(accountId != 0);
    }

    function test_createAccount_event() public {
        vm.prank(ACTOR);

        /// @custom:todo create and test event

        auth.createAccount();
    }

    function test_createAccount_with_marginEngine() public {
        vm.prank(ACTOR);

        accountId = auth.createAccount(MOCK_MARGIN_ENGINE);

        bool isMarginEngineRegistered =
            auth.hasAccountRegisteredMarginEngine(accountId, MOCK_MARGIN_ENGINE);

        assertTrue(isMarginEngineRegistered);
    }

    function test_createAccount_with_marginEngine_event() public {
        vm.prank(ACTOR);

        /// @custom:todo create and test event

        accountId = auth.createAccount(MOCK_MARGIN_ENGINE);
    }

    function test_createAccount_with_marginEngine_notZeroAddress() public {
        vm.prank(ACTOR);

        vm.expectRevert(abi.encodeWithSelector(Auth.ZeroAddress.selector));

        auth.createAccount(address(0));
    }
}

contract ActorManagement is AuthTest {
    uint128 accountId;

    function test_isCallerAccountActor() public {
        vm.prank(ACTOR);

        accountId = auth.createAccount();

        assertTrue(auth.isCallerAccountActor(ACTOR, accountId));
    }

    function test_getActorByAccountId() public {
        vm.prank(ACTOR);

        accountId = auth.createAccount();

        assertEq(auth.getActorByAccountId(accountId), ACTOR);
    }

    function test_getAccountIdsByActor() public {
        vm.prank(ACTOR);

        accountId = auth.createAccount();

        uint128[] memory accountIds = auth.getAccountIdsByActor(ACTOR);

        assertEq(accountIds.length, 1);
        assertEq(accountIds[0], accountId);
    }

    function test_changeAccountActor() public {
        vm.prank(ACTOR);

        accountId = auth.createAccount();

        vm.prank(ACTOR);

        auth.changeAccountActor(accountId, NEW_ACTOR);

        assertTrue(auth.isCallerAccountActor(NEW_ACTOR, accountId));
    }

    function test_changeAccountActor_event() public {
        vm.prank(ACTOR);

        accountId = auth.createAccount();

        vm.prank(ACTOR);

        /// @custom:todo create and test event

        auth.changeAccountActor(accountId, NEW_ACTOR);
    }

    function test_changeAccountActor_onlyAccountActor() public {
        vm.prank(ACTOR);

        accountId = auth.createAccount();

        vm.prank(BAD_ACTOR);

        vm.expectRevert(
            abi.encodeWithSelector(
                Auth.OnlyAccountActor.selector, accountId, ACTOR, BAD_ACTOR
            )
        );

        auth.changeAccountActor(accountId, BAD_ACTOR);
    }

    function test_changeAccountActor_notZeroAddress() public {
        vm.prank(ACTOR);

        accountId = auth.createAccount();

        vm.prank(ACTOR);

        vm.expectRevert(abi.encodeWithSelector(Auth.ZeroAddress.selector));

        auth.changeAccountActor(accountId, address(0));
    }

    function test_changeAccountActor_ownerByAccountId() public {
        vm.prank(ACTOR);

        accountId = auth.createAccount();

        vm.prank(ACTOR);

        auth.changeAccountActor(accountId, NEW_ACTOR);

        assertEq(auth.getActorByAccountId(accountId), NEW_ACTOR);
    }

    function test_changeAccountActor_accountIdsByOwner() public {
        vm.prank(ACTOR);

        accountId = auth.createAccount();

        vm.prank(ACTOR);

        auth.changeAccountActor(accountId, NEW_ACTOR);

        uint128[] memory accountIds = auth.getAccountIdsByActor(ACTOR);
        assertEq(accountIds.length, 0);

        accountIds = auth.getAccountIdsByActor(NEW_ACTOR);
        assertEq(accountIds.length, 1);
        assertEq(accountIds[0], accountId);
    }
}

contract DelegateManagement is AuthTest {
    uint128 accountId1;
    uint128 accountId2;
    uint128 accountId3;

    function test_addDelegate() public {
        vm.prank(ACTOR);

        accountId1 = auth.createAccount();

        vm.prank(ACTOR);

        auth.addDelegate(accountId1, DELEGATE_1);

        bool isDelegate;

        isDelegate = auth.isCallerAccountDelegate(DELEGATE_1, accountId1);
        assertTrue(isDelegate);
    }

    function test_addDelegate_event() public {
        vm.prank(ACTOR);

        accountId1 = auth.createAccount();

        vm.prank(ACTOR);

        /// @custom:todo create and test event

        auth.addDelegate(accountId1, DELEGATE_1);
    }

    function test_addDelegate_onlyAccountActor() public {
        vm.prank(BAD_ACTOR);

        vm.expectRevert(
            abi.encodeWithSelector(
                Auth.OnlyAccountActor.selector,
                accountId1,
                address(0),
                BAD_ACTOR
            )
        );

        auth.addDelegate(accountId1, DELEGATE_1);
    }

    function test_addDelegate_notZeroAddress() public {
        vm.prank(ACTOR);

        accountId1 = auth.createAccount();

        vm.prank(ACTOR);

        vm.expectRevert(abi.encodeWithSelector(Auth.ZeroAddress.selector));

        auth.addDelegate(accountId1, address(0));
    }

    function test_isCallerAccountDelegate() public {
        vm.startPrank(ACTOR);

        accountId1 = auth.createAccount();

        auth.addDelegate(accountId1, DELEGATE_1);
        auth.addDelegate(accountId1, DELEGATE_2);
        auth.addDelegate(accountId1, DELEGATE_3);

        vm.stopPrank();

        bool isDelegate;

        isDelegate = auth.isCallerAccountDelegate(DELEGATE_1, accountId1);
        assertTrue(isDelegate);

        isDelegate = auth.isCallerAccountDelegate(DELEGATE_2, accountId1);
        assertTrue(isDelegate);

        isDelegate = auth.isCallerAccountDelegate(DELEGATE_3, accountId1);
        assertTrue(isDelegate);
    }

    function test_getDelegatesByAccountId() public {
        vm.startPrank(ACTOR);

        accountId1 = auth.createAccount();

        auth.addDelegate(accountId1, DELEGATE_1);
        auth.addDelegate(accountId1, DELEGATE_2);
        auth.addDelegate(accountId1, DELEGATE_3);

        vm.stopPrank();

        address[] memory delegates;

        delegates = auth.getDelegatesByAccountId(accountId1);

        assertEq(delegates.length, 3);
        assertEq(delegates[0], DELEGATE_1);
        assertEq(delegates[1], DELEGATE_2);
        assertEq(delegates[2], DELEGATE_3);
    }

    function test_getAccountIdsByDelegate() public {
        vm.startPrank(ACTOR);

        accountId1 = auth.createAccount();
        accountId2 = auth.createAccount();
        accountId3 = auth.createAccount();

        auth.addDelegate(accountId1, DELEGATE_1);
        auth.addDelegate(accountId2, DELEGATE_1);
        auth.addDelegate(accountId3, DELEGATE_1);

        vm.stopPrank();

        uint128[] memory accountIds;

        accountIds = auth.getAccountIdsByDelegate(DELEGATE_1);

        assertEq(accountIds.length, 3);
        assertEq(accountIds[0], accountId1);
        assertEq(accountIds[1], accountId2);
        assertEq(accountIds[2], accountId3);
    }

    function test_removeDelegate() public {
        vm.startPrank(ACTOR);

        accountId1 = auth.createAccount();

        auth.addDelegate(accountId1, DELEGATE_1);
        auth.addDelegate(accountId1, DELEGATE_2);
        auth.addDelegate(accountId1, DELEGATE_3);

        auth.removeDelegate(accountId1, DELEGATE_2);

        vm.stopPrank();

        bool isDelegate;

        isDelegate = auth.isCallerAccountDelegate(DELEGATE_1, accountId1);
        assertTrue(isDelegate);

        isDelegate = auth.isCallerAccountDelegate(DELEGATE_2, accountId1);
        assertFalse(isDelegate);

        isDelegate = auth.isCallerAccountDelegate(DELEGATE_3, accountId1);
        assertTrue(isDelegate);
    }

    function test_removeDelegate_event() public {
        vm.startPrank(ACTOR);

        accountId1 = auth.createAccount();

        auth.addDelegate(accountId1, DELEGATE_1);

        /// @custom:todo create and test event

        auth.removeDelegate(accountId1, DELEGATE_2);

        vm.stopPrank();
    }

    function test_removeDelegate_onlyAccountActor() public {
        vm.prank(BAD_ACTOR);

        vm.expectRevert(
            abi.encodeWithSelector(
                Auth.OnlyAccountActor.selector,
                accountId1,
                address(0),
                BAD_ACTOR
            )
        );

        auth.removeDelegate(accountId1, DELEGATE_1);
    }

    function test_removeDelegate_delegatesByAccountId() public {
        vm.startPrank(ACTOR);

        accountId1 = auth.createAccount();

        auth.addDelegate(accountId1, DELEGATE_1);
        auth.addDelegate(accountId1, DELEGATE_2);
        auth.addDelegate(accountId1, DELEGATE_3);

        auth.removeDelegate(accountId1, DELEGATE_2);

        vm.stopPrank();

        address[] memory delegates;

        delegates = auth.getDelegatesByAccountId(accountId1);

        assertEq(delegates.length, 2);
        assertEq(delegates[0], DELEGATE_1);
        assertEq(delegates[1], DELEGATE_3);
    }

    function test_removeDelegate_accountIdsByDelegate() public {
        vm.startPrank(ACTOR);

        accountId1 = auth.createAccount();
        accountId2 = auth.createAccount();
        accountId3 = auth.createAccount();

        auth.addDelegate(accountId1, DELEGATE_1);
        auth.addDelegate(accountId2, DELEGATE_1);
        auth.addDelegate(accountId3, DELEGATE_1);

        auth.removeDelegate(accountId2, DELEGATE_1);

        vm.stopPrank();

        uint128[] memory accountIds;

        accountIds = auth.getAccountIdsByDelegate(DELEGATE_1);

        assertEq(accountIds.length, 2);
        assertEq(accountIds[0], accountId1);
        assertEq(accountIds[1], accountId3);
    }

    function test_remove_all_delegates_from_account() public {
        vm.startPrank(ACTOR);

        accountId1 = auth.createAccount();

        auth.addDelegate(accountId1, DELEGATE_1);
        auth.addDelegate(accountId1, DELEGATE_2);
        auth.addDelegate(accountId1, DELEGATE_3);

        auth.removeDelegate(accountId1, DELEGATE_1);
        auth.removeDelegate(accountId1, DELEGATE_2);
        auth.removeDelegate(accountId1, DELEGATE_3);

        vm.stopPrank();

        bool isDelegate;

        isDelegate = auth.isCallerAccountDelegate(DELEGATE_1, accountId1);
        assertFalse(isDelegate);

        isDelegate = auth.isCallerAccountDelegate(DELEGATE_2, accountId1);
        assertFalse(isDelegate);

        isDelegate = auth.isCallerAccountDelegate(DELEGATE_3, accountId1);
        assertFalse(isDelegate);

        address[] memory delegates;

        delegates = auth.getDelegatesByAccountId(accountId1);
        assertEq(delegates.length, 0);

        uint128[] memory accountIds;

        accountIds = auth.getAccountIdsByDelegate(DELEGATE_1);
        assertEq(accountIds.length, 0);

        accountIds = auth.getAccountIdsByDelegate(DELEGATE_2);
        assertEq(accountIds.length, 0);

        accountIds = auth.getAccountIdsByDelegate(DELEGATE_3);
        assertEq(accountIds.length, 0);
    }

    function test_remove_all_accounts_from_delegate() public {
        vm.startPrank(ACTOR);

        accountId1 = auth.createAccount();
        accountId2 = auth.createAccount();
        accountId3 = auth.createAccount();

        auth.addDelegate(accountId1, DELEGATE_1);
        auth.addDelegate(accountId2, DELEGATE_1);
        auth.addDelegate(accountId3, DELEGATE_1);

        auth.removeDelegate(accountId1, DELEGATE_1);
        auth.removeDelegate(accountId2, DELEGATE_1);
        auth.removeDelegate(accountId3, DELEGATE_1);

        vm.stopPrank();

        bool isDelegate;

        isDelegate = auth.isCallerAccountDelegate(DELEGATE_1, accountId1);
        assertFalse(isDelegate);

        isDelegate = auth.isCallerAccountDelegate(DELEGATE_1, accountId2);
        assertFalse(isDelegate);

        isDelegate = auth.isCallerAccountDelegate(DELEGATE_1, accountId3);
        assertFalse(isDelegate);

        address[] memory delegates;

        delegates = auth.getDelegatesByAccountId(accountId1);
        assertEq(delegates.length, 0);

        delegates = auth.getDelegatesByAccountId(accountId2);
        assertEq(delegates.length, 0);

        delegates = auth.getDelegatesByAccountId(accountId3);
        assertEq(delegates.length, 0);

        uint128[] memory accountIds;

        accountIds = auth.getAccountIdsByDelegate(DELEGATE_1);
        assertEq(accountIds.length, 0);
    }

    function test_removeDelegate_none_exists() public {
        vm.prank(ACTOR);

        accountId1 = auth.createAccount();

        assertFalse(auth.isCallerAccountDelegate(DELEGATE_1, accountId1));

        vm.prank(ACTOR);

        // no-op if delegate doesn't exist for account
        auth.removeDelegate(accountId1, DELEGATE_1);

        assertFalse(auth.isCallerAccountDelegate(DELEGATE_1, accountId1));
    }

    function test_removeDelegate_Twice() public {
        vm.startPrank(ACTOR);

        accountId1 = auth.createAccount();

        auth.addDelegate(accountId1, DELEGATE_1);

        auth.removeDelegate(accountId1, DELEGATE_1);

        // no-op if delegate doesn't exist for account
        auth.removeDelegate(accountId1, DELEGATE_1);

        vm.stopPrank();

        assertFalse(auth.isCallerAccountDelegate(DELEGATE_1, accountId1));
    }
}

contract MarginEngineManagement is AuthTest {
    uint128 accountId;

    function test_registerMarginEngine() public {
        vm.startPrank(ACTOR);

        accountId = auth.createAccount();

        auth.registerMarginEngine(accountId, MOCK_MARGIN_ENGINE);

        vm.stopPrank();

        bool isMarginEngineRegistered =
            auth.hasAccountRegisteredMarginEngine(accountId, MOCK_MARGIN_ENGINE);

        assertTrue(isMarginEngineRegistered);
    }

    function test_registerMarginEngine_event() public {
        vm.startPrank(ACTOR);

        accountId = auth.createAccount();

        /// @custom:todo create and test event

        auth.registerMarginEngine(accountId, MOCK_MARGIN_ENGINE);

        vm.stopPrank();
    }

    function test_registerMarginEngine_onlyAccountActor() public {
        vm.prank(BAD_ACTOR);

        vm.expectRevert(
            abi.encodeWithSelector(
                Auth.OnlyAccountActor.selector, accountId, address(0), BAD_ACTOR
            )
        );

        auth.registerMarginEngine(accountId, MOCK_MARGIN_ENGINE);
    }

    function test_registerMarginEngine_notZeroAddress() public {
        vm.prank(ACTOR);

        accountId = auth.createAccount();

        vm.prank(ACTOR);

        vm.expectRevert(abi.encodeWithSelector(Auth.ZeroAddress.selector));

        auth.registerMarginEngine(accountId, address(0));
    }

    function test_unregisterMarginEngine() public {
        vm.startPrank(ACTOR);

        accountId = auth.createAccount();

        auth.registerMarginEngine(accountId, MOCK_MARGIN_ENGINE);

        auth.unregisterMarginEngine(accountId, MOCK_MARGIN_ENGINE);

        vm.stopPrank();

        bool isMarginEngineRegistered =
            auth.hasAccountRegisteredMarginEngine(accountId, MOCK_MARGIN_ENGINE);

        assertFalse(isMarginEngineRegistered);
    }

    function test_unregisterMarginEngine_event() public {
        vm.startPrank(ACTOR);

        accountId = auth.createAccount();

        auth.registerMarginEngine(accountId, MOCK_MARGIN_ENGINE);

        /// @custom:todo create and test event

        auth.unregisterMarginEngine(accountId, MOCK_MARGIN_ENGINE);

        vm.stopPrank();
    }

    function test_unregisterMarginEngine_onlyAccountActor() public {
        vm.prank(BAD_ACTOR);

        vm.expectRevert(
            abi.encodeWithSelector(
                Auth.OnlyAccountActor.selector, accountId, address(0), BAD_ACTOR
            )
        );

        auth.unregisterMarginEngine(accountId, MOCK_MARGIN_ENGINE);
    }

    function test_unregisterMarginEngine_none_exists() public {
        vm.prank(ACTOR);

        accountId = auth.createAccount();

        vm.prank(ACTOR);

        vm.expectRevert(
            abi.encodeWithSelector(
                Auth.MarginEngineNotRegistered.selector,
                accountId,
                MOCK_MARGIN_ENGINE
            )
        );

        auth.unregisterMarginEngine(accountId, MOCK_MARGIN_ENGINE);

        assertFalse(
            auth.hasAccountRegisteredMarginEngine(accountId, MOCK_MARGIN_ENGINE)
        );
    }
}

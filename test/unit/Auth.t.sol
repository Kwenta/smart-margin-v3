// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Auth} from "src/modules/Auth.sol";
import {Constants} from "test/utils/Constants.sol";
import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";
import {OptimismGoerliParameters} from "script/Deploy.s.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract AuthTest is Test, Constants, OptimismGoerliParameters {
    Auth auth;
    IPerpsMarketProxy perpsMarketProxy;

    function setUp() public {
        vm.rollFork(GOERLI_BLOCK_NUMBER);
        perpsMarketProxy = IPerpsMarketProxy(OPTIMISM_GOERLI_PERPS_MARKET_PROXY);
        auth = new Auth(OPTIMISM_GOERLI_PERPS_MARKET_PROXY);
    }
}

contract Authentication is AuthTest {
    function test_isAccountOwner_true() public {
        vm.startPrank(ACTOR);
        uint128 accountId = perpsMarketProxy.createAccount();
        bool isOwner = auth.isAccountOwner(accountId);
        vm.stopPrank();

        assertTrue(isOwner);
    }

    function test_isAccountOwner_false() public {
        vm.prank(ACTOR);
        uint128 accountId = perpsMarketProxy.createAccount();

        vm.prank(BAD_ACTOR);
        bool isOwner = auth.isAccountOwner(accountId);

        assertFalse(isOwner);
    }

    function test_isAccountDelegate_true() public {
        vm.startPrank(ACTOR);
        uint128 accountId = perpsMarketProxy.createAccount();
        perpsMarketProxy.grantPermission({
            accountId: accountId,
            permission: "ADMIN",
            user: NEW_ACTOR
        });
        vm.stopPrank();

        vm.prank(NEW_ACTOR);
        bool isDelegate = auth.isAccountDelegate(accountId);

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

        vm.prank(BAD_ACTOR);
        bool isDelegate = auth.isAccountDelegate(accountId);

        assertFalse(isDelegate);
    }
}

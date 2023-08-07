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

    function test_AccountOwnership() public {
        vm.startPrank(owner);

        uint128 accountId = auth.createAccount();

        bool isOwner = auth.isCallerAccountOwner(accountId);
        assertTrue(isOwner);

        vm.stopPrank();
    }
}

contract Delegation is AuthenticationTest {
    address owner = address(0x1);
    address delegate1 = address(0x2);
    address delegate2 = address(0x3);
    address delegate3 = address(0x4);
    uint128 accountId1;
    uint128 accountId2;
    uint128 accountId3;
}

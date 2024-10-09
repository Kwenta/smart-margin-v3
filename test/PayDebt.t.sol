// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

import {Bootstrap} from "test/utils/Bootstrap.sol";

contract PayDebtTest is Bootstrap {
    function setUp() public {
        vm.rollFork(ARBITRUM_BLOCK_NUMBER);
        initializeArbitrum();
    }

    function testPayDebt() public {

        // todo

        vm.startPrank(ACTOR);
        sUSD.approve(address(engine), 1);
        engine.payDebt({
            _accountId: accountId,
            _amount: 1
        });
    }

    // todo test for auth

    // edge case tests

    // test paying debt with different setups?
}

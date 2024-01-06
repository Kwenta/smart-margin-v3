// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {IEngine} from "src/interfaces/IEngine.sol";
import {Bootstrap} from "test/utils/Bootstrap.sol";

contract CreditTest is Bootstrap {
    event Credited(uint128 indexed accountId, uint256 amount);
    event Debited(uint128 indexed accountId, uint256 amount);

    function setUp() public {
        vm.rollFork(BASE_BLOCK_NUMBER);
        initializeBase();
    }
}

contract Credit is CreditTest {
    function test_credit(uint256 amount) public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), amount);

        if (amount == 0) {
            string memory parameter = "amount";
            string memory reason = "Zero amount";

            vm.expectRevert(
                abi.encodeWithSelector(
                    InvalidParameter.selector, parameter, reason
                )
            );

            engine.creditAccount(accountId, amount);
        } else if (amount > sUSD.balanceOf(ACTOR)) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    InsufficientBalance.selector, amount, sUSD.balanceOf(ACTOR)
                )
            );

            engine.creditAccount(accountId, amount);
        } else {
            uint256 preEngineBalance = sUSD.balanceOf(address(engine));
            uint256 preActorBalance = sUSD.balanceOf(ACTOR);

            engine.creditAccount(accountId, amount);

            uint256 postEngineBalance = sUSD.balanceOf(address(engine));
            uint256 postActorBalance = sUSD.balanceOf(ACTOR);

            assert(postEngineBalance == preEngineBalance + amount);
            assert(postActorBalance == preActorBalance - amount);
        }

        vm.stopPrank();
    }

    function test_credit_event() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), AMOUNT);

        vm.expectEmit(true, true, true, true);
        emit Credited(accountId, AMOUNT);

        engine.creditAccount(accountId, AMOUNT);

        vm.stopPrank();
    }
}

contract Debit is CreditTest {
    function test_debit(uint256 amount) public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.creditAccount(accountId, AMOUNT);

        if (amount == 0) {
            string memory parameter = "amount";
            string memory reason = "Zero amount";

            vm.expectRevert(
                abi.encodeWithSelector(
                    InvalidParameter.selector, parameter, reason
                )
            );

            engine.debitAccount(accountId, amount);
        } else if (amount > engine.credit(accountId)) {
            vm.expectRevert(
                abi.encodeWithSelector(IEngine.InsufficientCredit.selector)
            );

            engine.debitAccount(accountId, amount);
        } else {
            uint256 preEngineBalance = sUSD.balanceOf(address(engine));
            uint256 preActorBalance = sUSD.balanceOf(ACTOR);

            engine.debitAccount(accountId, amount);

            uint256 postEngineBalance = sUSD.balanceOf(address(engine));
            uint256 postActorBalance = sUSD.balanceOf(ACTOR);

            assert(postEngineBalance == preEngineBalance - amount);
            assert(postActorBalance == preActorBalance + amount);
        }

        vm.stopPrank();
    }

    function test_debit_Unauthorized() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.creditAccount(accountId, AMOUNT);

        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(IEngine.Unauthorized.selector));

        vm.prank(BAD_ACTOR);

        engine.debitAccount(accountId, AMOUNT);
    }

    function test_debit_event() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.creditAccount(accountId, AMOUNT);

        vm.expectEmit(true, true, true, true);
        emit Debited(accountId, AMOUNT);

        engine.debitAccount(accountId, AMOUNT);

        vm.stopPrank();
    }

    function test_debit_InsufficientBalance() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.creditAccount(accountId, AMOUNT);

        vm.expectRevert(
            abi.encodeWithSelector(IEngine.InsufficientCredit.selector)
        );

        engine.debitAccount(accountId, AMOUNT + 1);

        vm.stopPrank();
    }
}

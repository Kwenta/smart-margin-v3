// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {IEngine} from "src/interfaces/IEngine.sol";
import {Bootstrap} from "test/utils/Bootstrap.sol";

contract CreditTest is Bootstrap {
    function setUp() public {
        vm.rollFork(GOERLI_BLOCK_NUMBER);
        initializeOptimismGoerli();
    }
}

contract Deposit is CreditTest {
    event Deposit(uint128 indexed accountId, uint256 amount);

    function test_deposit(uint256 amount) public {
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

            engine.deposit(accountId, amount);
        } else if (amount > sUSD.balanceOf(ACTOR)) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    InsufficientBalance.selector, amount, sUSD.balanceOf(ACTOR)
                )
            );

            engine.deposit(accountId, amount);
        } else {
            uint256 preEngineBalance = sUSD.balanceOf(address(engine));
            uint256 preActorBalance = sUSD.balanceOf(ACTOR);

            engine.deposit(accountId, amount);

            uint256 postEngineBalance = sUSD.balanceOf(address(engine));
            uint256 postActorBalance = sUSD.balanceOf(ACTOR);

            assert(postEngineBalance == preEngineBalance + amount);
            assert(postActorBalance == preActorBalance - amount);
        }

        vm.stopPrank();
    }

    function test_deposit_AccountDoesNotExist() public {
        assertEq(
            perpsMarketProxy.getAccountOwner(type(uint128).max), address(0)
        );

        vm.expectRevert(
            abi.encodeWithSelector(IEngine.AccountDoesNotExist.selector)
        );

        engine.deposit(type(uint128).max, AMOUNT);
    }

    function test_deposit_event() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), AMOUNT);

        vm.expectEmit(true, true, true, true);
        emit Deposit(accountId, AMOUNT);

        engine.deposit(accountId, AMOUNT);

        vm.stopPrank();
    }
}

contract Withdraw is CreditTest {
    event Withdraw(uint128 indexed accountId, uint256 amount);

    function test_withdraw(uint256 amount) public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.deposit(accountId, AMOUNT);

        if (amount == 0) {
            string memory parameter = "amount";
            string memory reason = "Zero amount";

            vm.expectRevert(
                abi.encodeWithSelector(
                    InvalidParameter.selector, parameter, reason
                )
            );

            engine.withdraw(accountId, amount);
        } else if (amount > engine.credit(accountId)) {
            vm.expectRevert(
                abi.encodeWithSelector(IEngine.InsufficientCredit.selector)
            );

            engine.withdraw(accountId, amount);
        } else {
            uint256 preEngineBalance = sUSD.balanceOf(address(engine));
            uint256 preActorBalance = sUSD.balanceOf(ACTOR);

            engine.withdraw(accountId, amount);

            uint256 postEngineBalance = sUSD.balanceOf(address(engine));
            uint256 postActorBalance = sUSD.balanceOf(ACTOR);

            assert(postEngineBalance == preEngineBalance - amount);
            assert(postActorBalance == preActorBalance + amount);
        }

        vm.stopPrank();
    }

    function test_withdraw_Unauthorized() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.deposit(accountId, AMOUNT);

        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(IEngine.Unauthorized.selector));

        vm.prank(BAD_ACTOR);

        engine.withdraw(accountId, AMOUNT);
    }

    function test_withdraw_event() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.deposit(accountId, AMOUNT);

        vm.expectEmit(true, true, true, true);
        emit Withdraw(accountId, AMOUNT);

        engine.withdraw(accountId, AMOUNT);

        vm.stopPrank();
    }

    function test_withdraw_InsufficientBalance() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.deposit(accountId, AMOUNT);

        vm.expectRevert(
            abi.encodeWithSelector(IEngine.InsufficientCredit.selector)
        );

        engine.withdraw(accountId, AMOUNT + 1);

        vm.stopPrank();
    }
}

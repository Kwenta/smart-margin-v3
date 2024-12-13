// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

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
            assert(engine.credit(accountId) == amount);
        }

        vm.stopPrank();
    }

    function test_credit_zap() public {
        uint256 decimalsFactor = 10 ** (18 - USDC.decimals());

        deal(address(USDC), ACTOR, SMALLEST_AMOUNT);

        vm.startPrank(ACTOR);

        USDC.approve(address(engine), type(uint256).max);

        uint256 preActorUSDCBalance = USDC.balanceOf(ACTOR);
        uint256 preEngineSUSDBalance = sUSD.balanceOf(address(engine));

        engine.creditAccountZap({
            _accountId: accountId,
            _amount: SMALLEST_AMOUNT,
            _amountOutMinimum: SMALLEST_AMOUNT - 3
        });

        uint256 postActorUSDCBalance = USDC.balanceOf(ACTOR);
        uint256 postEngineSUSDBalance = sUSD.balanceOf(address(engine));

        vm.stopPrank();

        assert(postActorUSDCBalance == preActorUSDCBalance - SMALLEST_AMOUNT);
        assertWithinTolerance(
            preEngineSUSDBalance + SMALLEST_AMOUNT * decimalsFactor,
            postEngineSUSDBalance,
            3
        );
        assertWithinTolerance(
            engine.credit(accountId), SMALLEST_AMOUNT * decimalsFactor, 3
        );
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
            assert(engine.credit(accountId) == AMOUNT - amount);
        }

        vm.stopPrank();
    }

    function test_debit_zap() public {
        uint256 decimalsFactor = 10 ** (18 - USDC.decimals());

        // this is 100 USDC
        uint256 amount = SMALLEST_AMOUNT * 10 ** 6;

        deal(address(USDC), ACTOR, amount);

        vm.startPrank(ACTOR);

        USDC.approve(address(engine), type(uint256).max);

        engine.creditAccountZap({
            _accountId: accountId,
            _amount: amount,
            _amountOutMinimum: amount * 97 / 100
        });

        uint256 preEngineSUSDBalance = sUSD.balanceOf(address(engine));
        // this gets the SUSD value in USDC decimals
        uint256 zapTolerance = preEngineSUSDBalance / decimalsFactor;
        uint256 preActorUSDCBalance = USDC.balanceOf(ACTOR);
        assertEq(preActorUSDCBalance, 0);
        assertWithinTolerance(
            engine.credit(accountId), amount * decimalsFactor, 3
        );

        engine.debitAccountZap({
            _accountId: accountId,
            _amount: preEngineSUSDBalance,
            _zapTolerance: zapTolerance
        });

        uint256 postActorUSDCBalance = USDC.balanceOf(ACTOR);
        uint256 postEngineSUSDBalance = sUSD.balanceOf(address(engine));
        assertEq(postEngineSUSDBalance, 0);
        assertWithinTolerance(
            postActorUSDCBalance, preActorUSDCBalance + amount, 3
        );
        assert(engine.credit(accountId) == 0);
    }

    function test_debit_zap_Unauthorized() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.creditAccount(accountId, AMOUNT);

        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(IEngine.Unauthorized.selector));

        vm.prank(BAD_ACTOR);

        engine.debitAccountZap({
            _accountId: accountId,
            _amount: AMOUNT,
            _zapTolerance: 1
        });
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

    function test_debit_zap_InsufficientBalance() public {
        uint256 decimalsFactor = 10 ** (18 - USDC.decimals());

        deal(address(USDC), ACTOR, SMALLEST_AMOUNT);

        vm.startPrank(ACTOR);

        USDC.approve(address(engine), type(uint256).max);

        engine.creditAccountZap({
            _accountId: accountId,
            _amount: SMALLEST_AMOUNT,
            _amountOutMinimum: SMALLEST_AMOUNT
        });

        vm.expectRevert(
            abi.encodeWithSelector(IEngine.InsufficientCredit.selector)
        );

        engine.debitAccountZap({
            _accountId: accountId,
            // this is how much credit is available    100_000000000000
            // this is how much we are trying to debit 100_000000000001
            _amount: (SMALLEST_AMOUNT * decimalsFactor) + 1,
            _zapTolerance: 1
        });

        vm.stopPrank();
    }
}

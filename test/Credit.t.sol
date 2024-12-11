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

    /// @custom:todo fix OracleDataRequired error
    // function test_credit_zap() public {
    //     uint256 decimalsFactor = 10 ** (18 - USDT.decimals());

    //     deal(address(USDT), ACTOR, SMALLEST_AMOUNT);

    //     vm.startPrank(ACTOR);

    //     USDT.approve(address(engine), type(uint256).max);

    //     uint256 preActorUSDTBalance = USDT.balanceOf(ACTOR);
    //     uint256 preEngineSUSDBalance = sUSD.balanceOf(address(engine));

    //     engine.creditAccountZap({
    //         _accountId: accountId,
    //         _amount: SMALLEST_AMOUNT,
    //         _collateral: USDT,
    //         _zapTolerance: SMALLEST_AMOUNT - 3
    //     });

    //     uint256 postActorUSDTBalance = USDT.balanceOf(ACTOR);
    //     uint256 postEngineSUSDBalance = sUSD.balanceOf(address(engine));

    //     vm.stopPrank();

    //     assert(postActorUSDTBalance == preActorUSDTBalance - SMALLEST_AMOUNT);
    //     assertWithinTolerance(
    //         preEngineSUSDBalance + SMALLEST_AMOUNT * decimalsFactor,
    //         postEngineSUSDBalance,
    //         3
    //     );
    //     assertWithinTolerance(
    //         engine.credit(accountId), SMALLEST_AMOUNT * decimalsFactor, 3
    //     );
    // }

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

    /// @custom:todo fix OracleDataRequired error
    // function test_debit_zap() public {
    //     uint256 decimalsFactor = 10 ** (18 - USDT.decimals());

    //     // this is 100 USDC/USDT
    //     uint256 amount = SMALLEST_AMOUNT * 10 ** 6;

    //     deal(address(USDT), ACTOR, amount);

    //     vm.startPrank(ACTOR);

    //     USDT.approve(address(engine), type(uint256).max);

    //     engine.creditAccountZap({
    //         _accountId: accountId,
    //         _amount: amount,
    //         _collateral: USDT,
    //         _zapTolerance: amount * 50 / 100
    //     });

    //     uint256 preActorUSDCBalance = USDC.balanceOf(ACTOR); // 0
    //     uint256 preEngineSUSDBalance = sUSD.balanceOf(address(engine)); // 59_811814806108750000
    //     // this gets the SUSD value in USDC decimals
    //     uint256 zapTolerance = preEngineSUSDBalance / decimalsFactor;
    //     assertEq(zapTolerance, 59_811_814);

    //     engine.debitAccountZap({
    //         _accountId: accountId,
    //         _amount: preEngineSUSDBalance,
    //         _zapTolerance: zapTolerance
    //     });

    //     uint256 postActorUSDCBalance = USDC.balanceOf(ACTOR); // 59_813355
    //     uint256 postEngineSUSDBalance = sUSD.balanceOf(address(engine)); // 0

    //     vm.stopPrank();

    //     // ~ 41% slippage when calling creditAccountZap
    //     assertWithinTolerance(
    //         preActorUSDCBalance + amount, postActorUSDCBalance, 45
    //     );
    //     assertWithinTolerance(
    //         postActorUSDCBalance * decimalsFactor, preEngineSUSDBalance, 3
    //     );
    //     assert(engine.credit(accountId) == 0);
    // }

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

    /// @custom:todo fix OracleDataRequired error
    // function test_debit_zap_InsufficientBalance() public {
    //     uint256 decimalsFactor = 10 ** (18 - USDT.decimals());

    //     deal(address(USDT), ACTOR, SMALLEST_AMOUNT);

    //     vm.startPrank(ACTOR);

    //     USDT.approve(address(engine), type(uint256).max);

    //     engine.creditAccountZap({
    //         _accountId: accountId,
    //         _amount: SMALLEST_AMOUNT,
    //         _collateral: USDT,
    //         _zapTolerance: SMALLEST_AMOUNT - 3
    //     });

    //     vm.expectRevert(
    //         abi.encodeWithSelector(IEngine.InsufficientCredit.selector)
    //     );

    //     engine.debitAccountZap({
    //         _accountId: accountId,
    //         // this is how much credit is available    97_997476500000
    //         // this is how much we are trying to debit 98_000000000000
    //         _amount: (SMALLEST_AMOUNT - 2) * decimalsFactor,
    //         _zapTolerance: 1
    //     });

    //     vm.stopPrank();
    // }
}

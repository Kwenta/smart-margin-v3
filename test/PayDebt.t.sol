// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

import {Bootstrap} from "test/utils/Bootstrap.sol";
import {IEngine} from "src/interfaces/IEngine.sol";

contract PayDebtTest is Bootstrap {
    address public constant DEBT_ACTOR =
        address(0x325cd6b3CD80EDB102ac78848f5B127eB6DB13f3);
    uint128 public constant ACCOUNT_ID =
        170_141_183_460_469_231_731_687_303_715_884_105_747;
    uint256 public constant INITIAL_DEBT = 1_415_390_413_007_519_465;
    uint256 public constant BASE_BLOCK_NUMBER_WITH_DEBT = 23_779_991;
    uint256 public constant USDC_WRAPPER_MAX_AMOUNT = 100_000_000_000_000_000_000_000_000;

    function setUp() public {
        vm.rollFork(BASE_BLOCK_NUMBER_WITH_DEBT);
        initializeBase();

        synthMinter.mint_sUSD(DEBT_ACTOR, AMOUNT);
        deal(address(USDC), DEBT_ACTOR, AMOUNT);
    }

    function test_payDebt_Unauthorized() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), INITIAL_DEBT);

        vm.expectRevert(abi.encodeWithSelector(IEngine.Unauthorized.selector));

        engine.payDebt({_accountId: ACCOUNT_ID, _amount: INITIAL_DEBT});
    }

    function test_payDebtWithUSDC_Unauthorized() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), INITIAL_DEBT);

        vm.expectRevert(abi.encodeWithSelector(IEngine.Unauthorized.selector));

        engine.payDebtWithUSDC({_accountId: ACCOUNT_ID, _amount: INITIAL_DEBT, _zapMinAmountOut: 1});
    }

    function test_payDebt() public {
        /// @dev on this block (BASE_BLOCK_NUMBER_WITH_DEBT)
        /// ACCOUNT_ID has a debt value of INITIAL_DEBT
        uint256 initialAccountDebt = perpsMarketProxy.debt(ACCOUNT_ID);
        assertEq(initialAccountDebt, INITIAL_DEBT);

        uint256 initialSUSD = sUSD.balanceOf(DEBT_ACTOR);

        vm.startPrank(DEBT_ACTOR);

        sUSD.approve(address(engine), INITIAL_DEBT);

        engine.payDebt({_accountId: ACCOUNT_ID, _amount: INITIAL_DEBT});
        vm.stopPrank();

        uint256 finalAccountDebt = perpsMarketProxy.debt(ACCOUNT_ID);
        assertEq(finalAccountDebt, 0);

        uint256 finalSUSD = sUSD.balanceOf(DEBT_ACTOR);
        assertEq(finalSUSD, initialSUSD - INITIAL_DEBT);
    }

    /// @notice asserts that if amount passed is greater than debt, 
    /// @notice excess sUSD is sent back to the user after paying off the debt
    function test_payDebt_overpay() public {
        /// @dev on this block (BASE_BLOCK_NUMBER_WITH_DEBT)
        /// ACCOUNT_ID has a debt value of INITIAL_DEBT
        uint256 initialAccountDebt = perpsMarketProxy.debt(ACCOUNT_ID);
        assertEq(initialAccountDebt, INITIAL_DEBT);

        uint256 initialSUSD = sUSD.balanceOf(DEBT_ACTOR);

        vm.startPrank(DEBT_ACTOR);

        sUSD.approve(address(engine), INITIAL_DEBT + SMALLEST_AMOUNT);

        engine.payDebt({
            _accountId: ACCOUNT_ID,
            _amount: INITIAL_DEBT + SMALLEST_AMOUNT
        });
        vm.stopPrank();

        uint256 finalAccountDebt = perpsMarketProxy.debt(ACCOUNT_ID);
        assertEq(finalAccountDebt, 0);

        uint256 finalSUSD = sUSD.balanceOf(DEBT_ACTOR);
        assertEq(finalSUSD, initialSUSD - INITIAL_DEBT);
    }

    function test_payDebt_Fuzz(uint256 amount) public {
        vm.assume(amount < AMOUNT);
        vm.assume(amount > SMALLEST_AMOUNT);

        /// @dev on this block (BASE_BLOCK_NUMBER_WITH_DEBT)
        /// ACCOUNT_ID has a debt value of INITIAL_DEBT
        uint256 initialAccountDebt = perpsMarketProxy.debt(ACCOUNT_ID);
        assertEq(initialAccountDebt, INITIAL_DEBT);

        uint256 initialSUSD = sUSD.balanceOf(DEBT_ACTOR);

        vm.startPrank(DEBT_ACTOR);

        sUSD.approve(address(engine), amount);

        engine.payDebt({_accountId: ACCOUNT_ID, _amount: amount});

        vm.stopPrank();

        uint256 finalAccountDebt = perpsMarketProxy.debt(ACCOUNT_ID);
        uint256 finalSUSD = sUSD.balanceOf(DEBT_ACTOR);

        if (amount > INITIAL_DEBT) {
            // If amount is greater than the initial debt, the debt should be fully paid
            // and excess sUSD should be sent back to the user
            assertEq(finalAccountDebt, 0);
            assertEq(finalSUSD, initialSUSD - INITIAL_DEBT);
        } else {
            // If amount is less or equal than the initial debt, only part of the debt is paid
            assertEq(finalAccountDebt, INITIAL_DEBT - amount);
            assertEq(finalSUSD, initialSUSD - amount);
        }
    }

    function test_payDebtWithUSDC() public {
        /// @dev INITIAL_DEBT is in sUSD (18 decimals)
        /// so we need to convert it to USDC (6 decimals)
        /// (for the input _amount)
        uint256 decimalsFactor = 10 ** (18 - USDC.decimals());
        uint256 INITIAL_DEBT_IN_USDC = INITIAL_DEBT / decimalsFactor;
        assertEq(INITIAL_DEBT_IN_USDC, 1_415_390);

        /// @dev on this block (BASE_BLOCK_NUMBER_WITH_DEBT)
        /// ACCOUNT_ID has a debt value of INITIAL_DEBT
        uint256 initialAccountDebt = perpsMarketProxy.debt(ACCOUNT_ID);
        assertEq(initialAccountDebt, INITIAL_DEBT);

        uint256 initialSUSD = sUSD.balanceOf(DEBT_ACTOR);
        uint256 initialUSDC = USDC.balanceOf(DEBT_ACTOR);

        vm.startPrank(DEBT_ACTOR);
        /// @dev remember we need to approve the excess amount as well (+1)
        USDC.approve(address(engine), INITIAL_DEBT_IN_USDC + 1);
        engine.payDebtWithUSDC({_accountId: ACCOUNT_ID, _amount: INITIAL_DEBT_IN_USDC, _zapMinAmountOut: INITIAL_DEBT_IN_USDC});
        vm.stopPrank();

        uint256 finalAccountDebt = perpsMarketProxy.debt(ACCOUNT_ID);
        assertEq(finalAccountDebt, 0);

        /// @dev the sUSD balance should stay the same because
        /// the user paid the debt with USDC
        uint256 finalSUSD = sUSD.balanceOf(DEBT_ACTOR);
        assertEq(finalSUSD, initialSUSD);

        uint256 finalUSDC = USDC.balanceOf(DEBT_ACTOR);
        assertEq(finalUSDC, initialUSDC - (INITIAL_DEBT_IN_USDC + 1));
    }

    /// @notice asserts that if amount passed is greater than debt, 
    /// @notice excess USDC is sent back to the user after paying off the debt
    function test_payDebtWithUSDC_overpay() public {
        /// @dev INITIAL_DEBT is in sUSD (18 decimals)
        /// so we need to convert it to USDC (6 decimals)
        /// (for the input _amount)
        uint256 decimalsFactor = 10 ** (18 - USDC.decimals());
        uint256 INITIAL_DEBT_IN_USDC = INITIAL_DEBT / decimalsFactor;
        assertEq(INITIAL_DEBT_IN_USDC, 1_415_390);

        /// @dev on this block (BASE_BLOCK_NUMBER_WITH_DEBT)
        /// @dev ACCOUNT_ID has a debt value of INITIAL_DEBT
        uint256 initialAccountDebt = perpsMarketProxy.debt(ACCOUNT_ID);
        assertEq(initialAccountDebt, INITIAL_DEBT);

        uint256 initialSUSD = sUSD.balanceOf(DEBT_ACTOR);
        uint256 initialUSDC = USDC.balanceOf(DEBT_ACTOR);
        /// @dev overpay by 1 USDC
        uint256 overpay = 1 * decimalsFactor;

        vm.startPrank(DEBT_ACTOR);
        /// @dev remember we need to approve the excess amount as well (+1)
        USDC.approve(address(engine), INITIAL_DEBT_IN_USDC + overpay + 1);
        engine.payDebtWithUSDC({
            _accountId: ACCOUNT_ID,
            _amount: INITIAL_DEBT_IN_USDC + overpay,
            _zapMinAmountOut: INITIAL_DEBT_IN_USDC + overpay
        });
        vm.stopPrank();

        uint256 finalAccountDebt = perpsMarketProxy.debt(ACCOUNT_ID);
        assertEq(finalAccountDebt, 0);

        /// @dev the sUSD balance should stay the same because
        /// the user paid the debt with USDC
        uint256 finalSUSD = sUSD.balanceOf(DEBT_ACTOR);
        assertEq(finalSUSD, initialSUSD);

        uint256 finalUSDC = USDC.balanceOf(DEBT_ACTOR);
        assertEq(finalUSDC, initialUSDC - (INITIAL_DEBT_IN_USDC + 1));
    }

    function test_payDebtWithUSDC_Fuzz(uint32 amount) public {
        vm.assume(amount < USDC_WRAPPER_MAX_AMOUNT);
        vm.assume(amount < AMOUNT);
        vm.assume(amount > SMALLEST_AMOUNT);

        /// @dev INITIAL_DEBT is in sUSD (18 decimals)
        /// so we need to convert it to USDC (6 decimals)
        /// (for the input _amount)
        uint256 decimalsFactor = 10 ** (18 - USDC.decimals());
        uint256 INITIAL_DEBT_IN_USDC = INITIAL_DEBT / decimalsFactor;
        assertEq(INITIAL_DEBT_IN_USDC, 1_415_390);

        /// @dev on this block (BASE_BLOCK_NUMBER_WITH_DEBT)
        /// @dev ACCOUNT_ID has a debt value of INITIAL_DEBT
        uint256 initialAccountDebt = perpsMarketProxy.debt(ACCOUNT_ID);
        assertEq(initialAccountDebt, INITIAL_DEBT);

        uint256 initialSUSD = sUSD.balanceOf(DEBT_ACTOR);
        uint256 initialUSDC = USDC.balanceOf(DEBT_ACTOR);

        vm.startPrank(DEBT_ACTOR);
        /// @dev remember we need to approve the excess amount as well (+1)
        USDC.approve(address(engine), uint256(amount) + 1);
        engine.payDebtWithUSDC({
            _accountId: ACCOUNT_ID,
            _amount: amount,
            _zapMinAmountOut: amount
        });
        vm.stopPrank();

        uint256 finalAccountDebt = perpsMarketProxy.debt(ACCOUNT_ID);
        uint256 finalSUSD = sUSD.balanceOf(DEBT_ACTOR);
        uint256 finalUSDC = USDC.balanceOf(DEBT_ACTOR);

        if (amount > INITIAL_DEBT_IN_USDC) {
            // If amount is greater than the initial debt, the debt should be fully paid
            // and excess sUSD should be sent back to the user
            assertEq(finalAccountDebt, 0);
            assertEq(finalUSDC, initialUSDC - (INITIAL_DEBT_IN_USDC + 1));
        } else {
            // If amount is less or equal than the initial debt, only part of the debt is paid
            assertEq(finalAccountDebt, INITIAL_DEBT - ((amount + 1) * decimalsFactor));
            assertEq(finalUSDC, initialUSDC - (uint256(amount) + 1));
        }
        /// @dev the sUSD balance should stay the same because
        /// the user paid the debt with USDC
        assertEq(finalSUSD, initialSUSD);
    }
}

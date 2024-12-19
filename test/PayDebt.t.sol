// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

import {Bootstrap} from "test/utils/Bootstrap.sol";
import {IEngine} from "src/interfaces/IEngine.sol";

contract PayDebtTest is Bootstrap {
    address public constant DEBT_ACTOR =
        address(0x3C704e28C8EfCC7aCa262031818001895595081D);
    uint128 public constant ACCOUNT_ID =
        170_141_183_460_469_231_731_687_303_715_884_108_662;
    uint256 public constant INITIAL_DEBT = 10_718_269_732_520_293_989;
    uint256 public constant BASE_BLOCK_NUMBER_WITH_DEBT = 23_922_058;
    uint256 public constant USDC_WRAPPER_MAX_AMOUNT =
        100_000_000_000_000_000_000_000_000;

    function setUp() public {
        vm.rollFork(BASE_BLOCK_NUMBER_WITH_DEBT);
        initializeBase();

        deal(address(USDC), DEBT_ACTOR, AMOUNT);
    }

    function test_payDebtWithUSDC_Unauthorized() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), INITIAL_DEBT);

        vm.expectRevert(abi.encodeWithSelector(IEngine.Unauthorized.selector));

        engine.payDebtWithUSDC({
            _accountId: ACCOUNT_ID,
            _amount: INITIAL_DEBT,
            _zapMinAmountOut: 1
        });
    }

    function test_payDebtWithUSDC() public {
        /// @dev INITIAL_DEBT is in sUSD (18 decimals)
        /// so we need to convert it to USDC (6 decimals)
        /// (for the input _amount)
        uint256 decimalsFactor = 10 ** (18 - USDC.decimals());
        uint256 INITIAL_DEBT_IN_USDC = INITIAL_DEBT / decimalsFactor;
        assertEq(INITIAL_DEBT_IN_USDC, 10_718_269);

        /// @dev on this block (BASE_BLOCK_NUMBER_WITH_DEBT)
        /// ACCOUNT_ID has a debt value of INITIAL_DEBT
        uint256 initialAccountDebt = perpsMarketProxy.debt(ACCOUNT_ID);
        assertEq(initialAccountDebt, INITIAL_DEBT);

        uint256 initialSUSD = sUSD.balanceOf(DEBT_ACTOR);
        uint256 initialUSDC = USDC.balanceOf(DEBT_ACTOR);

        vm.startPrank(DEBT_ACTOR);
        /// @dev remember we need to approve the excess amount as well (+1)
        USDC.approve(address(engine), INITIAL_DEBT_IN_USDC + 1);
        engine.payDebtWithUSDC({
            _accountId: ACCOUNT_ID,
            _amount: INITIAL_DEBT_IN_USDC,
            _zapMinAmountOut: INITIAL_DEBT_IN_USDC
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

    /// @notice asserts that if amount passed is greater than debt,
    /// @notice excess USDC is sent back to the user after paying off the debt
    function test_payDebtWithUSDC_overpay() public {
        /// @dev INITIAL_DEBT is in sUSD (18 decimals)
        /// so we need to convert it to USDC (6 decimals)
        /// (for the input _amount)
        uint256 decimalsFactor = 10 ** (18 - USDC.decimals());
        uint256 INITIAL_DEBT_IN_USDC = INITIAL_DEBT / decimalsFactor;
        assertEq(INITIAL_DEBT_IN_USDC, 10_718_269);

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
        assertEq(INITIAL_DEBT_IN_USDC, 10_718_269);

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
            assertEq(
                finalAccountDebt, INITIAL_DEBT - ((amount + 1) * decimalsFactor)
            );
            assertEq(finalUSDC, initialUSDC - (uint256(amount) + 1));
        }
        /// @dev the sUSD balance should stay the same because
        /// the user paid the debt with USDC
        assertEq(finalSUSD, initialSUSD);
    }
}

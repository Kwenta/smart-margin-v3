// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

import {Bootstrap} from "test/utils/Bootstrap.sol";

contract CollateralTest is Bootstrap {
    function setUp() public {
        vm.rollFork(ARBITRUM_BLOCK_NUMBER);
        initializeArbitrum();
    }
}

contract DepositCollateral is CollateralTest {
    function test_depositCollateral() public {
        uint256 preBalance = sUSD.balanceOf(ACTOR);

        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        vm.stopPrank();

        uint256 postBalance = sUSD.balanceOf(ACTOR);

        assertEq(postBalance, preBalance - AMOUNT);
    }

    function test_depositCollateral_availableMargin() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        vm.stopPrank();

        int256 availableMargin = perpsMarketProxy.getAvailableMargin(accountId);
        assertEq(availableMargin, int256(AMOUNT));
    }

    function test_depositCollateral_collateralAmount() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        vm.stopPrank();

        uint256 collateralAmountOfSynth =
            perpsMarketProxy.getCollateralAmount(accountId, SUSD_SPOT_MARKET_ID);
        assertEq(collateralAmountOfSynth, AMOUNT);
    }

    function test_depositCollateral_totalCollateralValue() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        vm.stopPrank();

        uint256 totalCollateralValue =
            perpsMarketProxy.totalCollateralValue(accountId);
        assertEq(totalCollateralValue, AMOUNT);
    }

    function test_depositCollateral_insufficient_balance() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        vm.expectRevert(
            abi.encodeWithSelector(
                InsufficientBalance.selector, AMOUNT + 1, AMOUNT
            )
        );

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT + 1)
        });

        vm.stopPrank();
    }

    function assertWithinTolerance(int256 expected, int256 actual, uint256 tolerancePercent) internal {
        int256 tolerance = (expected * int256(tolerancePercent)) / 100;
        assert(actual >= expected - tolerance && actual <= expected + tolerance);
    }

    function test_depositCollateral_zap() public {
        uint256 decimalsFactor = 10 ** (18 - USDT.decimals());

        deal(address(USDT), ACTOR, SMALLEST_AMOUNT);

        vm.startPrank(ACTOR);

        USDT.approve(address(engine), type(uint256).max);
        
        engine.modifyCollateralZap({
            _accountId: accountId,
            _amount: int256(SMALLEST_AMOUNT),
            _swapTolerance: SMALLEST_AMOUNT - 3,
            _zapTolerance: SMALLEST_AMOUNT - 3,
            _collateral: USDT
        });
        
        vm.stopPrank();

        int256 availableMargin = perpsMarketProxy.getAvailableMargin(accountId);
        int256 expectedMargin = int256(SMALLEST_AMOUNT);
        assertWithinTolerance(expectedMargin, availableMargin, 3);
    }

    function test_depositCollateral_wrap() public {
        deal(address(WETH), ACTOR, SMALLER_AMOUNT);

        vm.startPrank(ACTOR);

        WETH.approve(address(engine), type(uint256).max);
        
        engine.modifyCollateralWrap({
            _accountId: accountId,
            _amount: int256(SMALLER_AMOUNT),
            _tolerance: SMALLER_AMOUNT - 3,
            _collateral: WETH,
            _synthMarketId: 4
        });
        
        vm.stopPrank();

        int256 availableMargin = perpsMarketProxy.getAvailableMargin(accountId);
        int256 expectedMargin = int256(SMALLER_AMOUNT) * int256(ETH_PRICE);
        assertWithinTolerance(expectedMargin, availableMargin, 2);
    }

    function test_depositCollateral_wrapfail() public {
        // fail if the collateral is not a supported collateral at synthetix
        deal(address(USDC), ACTOR, SMALLEST_AMOUNT);

        vm.startPrank(ACTOR);

        USDC.approve(address(engine), type(uint256).max);
        
        vm.expectRevert();
        engine.modifyCollateralWrap({
            _accountId: accountId,
            _amount: int256(SMALLEST_AMOUNT),
            _tolerance: SMALLEST_AMOUNT - 3,
            _collateral: USDC,
            _synthMarketId: 2
        });
        
    }

    function test_depositCollateral_ETH() public {
        vm.deal(ACTOR, SMALLER_AMOUNT);

        vm.startPrank(ACTOR);
        
        engine.depositCollateralETH{value: SMALLER_AMOUNT}({
            _accountId: accountId,
            _tolerance: SMALLER_AMOUNT
        });
        
        vm.stopPrank();

        int256 availableMargin = perpsMarketProxy.getAvailableMargin(accountId);
        int256 expectedMargin = int256(SMALLER_AMOUNT) * int256(ETH_PRICE);
        assertWithinTolerance(expectedMargin, availableMargin, 2);
    }

    function testFuzz_depositCollateral_ETH(uint256 amount) public {
        /// @dev amount must be less than max MarketCollateralAmount
        vm.assume(amount < 1000000000000000000000);
        vm.assume(amount > SMALLEST_AMOUNT);
        vm.deal(ACTOR, amount);

        vm.startPrank(ACTOR);
        
        engine.depositCollateralETH{value: amount}({
            _accountId: accountId,
            _tolerance: amount * 97 / 100
        });
        
        vm.stopPrank();

        int256 availableMargin = perpsMarketProxy.getAvailableMargin(accountId);
        int256 expectedMargin = int256(amount) * int256(ETH_PRICE);
        assertWithinTolerance(expectedMargin, availableMargin, 3);
    }
}

contract WithdrawCollateral is CollateralTest {
    function test_withdrawCollateral() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        uint256 preBalance = sUSD.balanceOf(ACTOR);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: -int256(SMALLER_AMOUNT)
        });

        vm.stopPrank();

        uint256 postBalance = sUSD.balanceOf(ACTOR);

        assertEq(postBalance, preBalance + SMALLER_AMOUNT);
    }

    function test_withdrawCollateral_zero() public {
        /// @notice is amount is zero, modifyCollateral will logically treat
        /// the interaction as a withdraw which will then revert

        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        vm.expectRevert(abi.encodeWithSelector(InvalidAmountDelta.selector, 0));

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: 0
        });

        vm.stopPrank();
    }

    function test_withdrawCollateral_insufficient_account_collateral_balance()
        public
    {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                InsufficientSynthCollateral.selector,
                SUSD_SPOT_MARKET_ID,
                AMOUNT,
                AMOUNT + 1
            )
        );

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: -int256(AMOUNT + 1)
        });

        vm.stopPrank();
    }

    function assertWithinTolerance(int256 expected, int256 actual, uint256 tolerancePercent) internal {
        int256 tolerance = (expected * int256(tolerancePercent)) / 100;
        assert(actual >= expected - tolerance && actual <= expected + tolerance);
    }

    function test_withdrawCollateral_zap() public {
        uint256 decimalsFactor = 10 ** (18 - USDT.decimals());

        // vm.startPrank(ACTOR);

        // sUSD.approve(address(engine), type(uint256).max);

        // engine.modifyCollateral({
        //     _accountId: accountId,
        //     _synthMarketId: SUSD_SPOT_MARKET_ID,
        //     //_synthMarketId: 2,
        //     _amount: int256(AMOUNT)
        // });

        deal(address(USDT), ACTOR, SMALLER_AMOUNT);

        vm.startPrank(ACTOR);

        USDT.approve(address(engine), type(uint256).max);
        
        // add the collateral
        engine.modifyCollateralZap({
            _accountId: accountId,
            _amount: int256(SMALLER_AMOUNT),
            _swapTolerance: 1,
            _zapTolerance: 1,
            _collateral: USDT
        });

        // @florian above is what you can comment out to uncomment modifyCollateral "classic"

        // remove the collateral
        engine.modifyCollateralZap({
            _accountId: accountId,
            _amount: -int256(78133551009252750000),
            _swapTolerance: 1,
            _zapTolerance: 1,
            _collateral: USDT
        });

        // vm.stopPrank();
        // uint256 postBalance = USDC.balanceOf(ACTOR);
        // int256 expectedBalance = int256(SMALLER_AMOUNT) * int256(decimalsFactor);
        // // todo below is going to fail because slippage is like >99%
        // assertWithinTolerance(expectedBalance, int256(postBalance), 5);
    }

    function test_withdrawCollateral_wrap() public {
        //uint256 decimalsFactor = 10 ** (18 - USDC.decimals());

        deal(address(WETH), ACTOR, SMALLEST_AMOUNT);

        vm.startPrank(ACTOR);

        WETH.approve(address(engine), type(uint256).max);
        
        engine.modifyCollateralWrap({
            _accountId: accountId,
            _amount: -int256(SMALLEST_AMOUNT),
            _tolerance: SMALLEST_AMOUNT - 3,
            _collateral: WETH,
            _synthMarketId: 4
        });
        
        vm.stopPrank();

        // int256 availableMargin = perpsMarketProxy.getAvailableMargin(accountId);
        // int256 expectedMargin = int256(SMALLEST_AMOUNT) * int256(decimalsFactor);
        // assertWithinTolerance(expectedMargin, availableMargin, 3);
    }

    function test_withdrawCollateral_ETH() public {
        uint256 preBalance = ACTOR.balance;

        vm.deal(ACTOR, SMALLER_AMOUNT);

        vm.startPrank(ACTOR);
        
        engine.depositCollateralETH{value: SMALLER_AMOUNT}({
            _accountId: accountId,
            _tolerance: SMALLER_AMOUNT
        });

        engine.withdrawCollateralETH({
            _accountId: accountId,
            _amount: int256(SMALLER_AMOUNT),
            _tolerance: SMALLER_AMOUNT
        });
        
        vm.stopPrank();

        uint256 postBalance = ACTOR.balance;
        assertEq(postBalance, preBalance + SMALLER_AMOUNT);
    }

    function testFuzz_withdrawCollateral_ETH(uint256 amount) public {
        uint256 preBalance = ACTOR.balance;

        /// @dev amount must be less than max MarketCollateralAmount
        vm.assume(amount < 1000000000000000000000);
        vm.assume(amount > SMALLEST_AMOUNT);
        vm.deal(ACTOR, amount);

        vm.startPrank(ACTOR);
        
        engine.depositCollateralETH{value: amount}({
            _accountId: accountId,
            _tolerance: amount * 97 / 100
        });

        engine.withdrawCollateralETH({
            _accountId: accountId,
            _amount: int256(amount) - 1,
            _tolerance: amount * 97 / 100
        });
        
        vm.stopPrank();

        uint256 postBalance = ACTOR.balance;
        assertWithinTolerance(int256(preBalance + amount), int256(postBalance), 3);
    }
}

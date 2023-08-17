// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Bootstrap} from "test/utils/Bootstrap.sol";

contract CollateralTest is Bootstrap {
    function setUp() public {
        vm.rollFork(GOERLI_BLOCK_NUMBER);
        initializeOptimismGoerli();
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
}

contract WithdrawCollateral is CollateralTest {
    function test_withdrawCollateral() public {
        uint256 preBalance = sUSD.balanceOf(ACTOR);

        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: -int256(AMOUNT)
        });

        vm.stopPrank();

        uint256 postBalance = sUSD.balanceOf(ACTOR);

        assertEq(postBalance, preBalance);
    }

    function test_withdrawCollateral_availableMargin() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: -int256(AMOUNT)
        });

        vm.stopPrank();

        int256 availableMargin = perpsMarketProxy.getAvailableMargin(accountId);
        assertEq(availableMargin, 0);
    }

    function test_withdrawCollateral_collateralAmount() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: -int256(AMOUNT)
        });

        vm.stopPrank();

        uint256 collateralAmountOfSynth =
            perpsMarketProxy.getCollateralAmount(accountId, SUSD_SPOT_MARKET_ID);
        assertEq(collateralAmountOfSynth, 0);
    }

    function test_withdrawCollateral_totalCollateralValue() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: -int256(AMOUNT)
        });

        vm.stopPrank();

        uint256 totalCollateralValue =
            perpsMarketProxy.totalCollateralValue(accountId);
        assertEq(totalCollateralValue, 0);
    }
}

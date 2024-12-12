// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

import {IEngine} from "src/interfaces/IEngine.sol";
import {Bootstrap} from "test/utils/Bootstrap.sol";

contract CollateralTest is Bootstrap {
    function setUp() public {
        vm.rollFork(BASE_BLOCK_NUMBER);
        initializeBase();
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

    function test_depositCollateral_zap() public {
        uint256 decimalsFactor = 10 ** (18 - USDC.decimals());

        deal(address(USDC), ACTOR, SMALLEST_AMOUNT);

        vm.startPrank(ACTOR);

        USDC.approve(address(engine), type(uint256).max);

        uint256 availableMarginBefore =
            uint256(perpsMarketProxy.getAvailableMargin(accountId));
        assertEq(availableMarginBefore, 0);

        engine.modifyCollateralZap({
            _accountId: accountId,
            _amount: int256(SMALLEST_AMOUNT),
            _zapMinAmountOut: SMALLEST_AMOUNT - 3
        });

        vm.stopPrank();

        uint256 availableMargin =
            uint256(perpsMarketProxy.getAvailableMargin(accountId));
        uint256 expectedMargin = SMALLEST_AMOUNT * decimalsFactor;
        assertWithinTolerance(expectedMargin, availableMargin, 3);
    }

    function test_depositCollateral_wrap() public {
        deal(address(WETH), ACTOR, SMALLER_AMOUNT);

        vm.startPrank(ACTOR);

        WETH.approve(address(engine), type(uint256).max);

        uint256 availableMarginBefore =
            uint256(perpsMarketProxy.getAvailableMargin(accountId));
        assertEq(availableMarginBefore, 0);

        engine.modifyCollateralWrap({
            _accountId: accountId,
            _amount: int256(SMALLER_AMOUNT),
            _tolerance: SMALLER_AMOUNT,
            _collateral: WETH,
            _synthMarketId: WETH_SYNTH_MARKET_ID
        });

        vm.stopPrank();

        uint256 availableMargin =
            uint256(perpsMarketProxy.getAvailableMargin(accountId));
        uint256 expectedMargin = SMALLER_AMOUNT * ETH_PRICE;
        assertWithinTolerance(expectedMargin, availableMargin, 2);
    }

    /// @custom:todo fix OracleDataRequired error
    // function test_depositCollateral_wrapCBBTC() public {
    //     deal(address(cbBTC), ACTOR, 1);

    //     vm.startPrank(ACTOR);

    //     cbBTC.approve(address(engine), type(uint256).max);

    // uint256 availableMarginBefore =
    //     uint256(perpsMarketProxy.getAvailableMargin(accountId));
    // assertEq(availableMarginBefore, 0);

    //     engine.modifyCollateralWrap({
    //         _accountId: accountId,
    //         _amount: int256(1),
    //         _tolerance: 1,
    //         _collateral: cbBTC,
    //         _synthMarketId: CBBTC_SYNTH_MARKET_ID
    //     });

    //     vm.stopPrank();

    //     // uint256 availableMargin = uint256(perpsMarketProxy.getAvailableMargin(accountId));
    //     // uint256 expectedMargin = BTC_PRICE; // todo add BTC_PRICE to constants
    //     // assertWithinTolerance(expectedMargin, availableMargin, 2);
    // }

    /// @custom:todo fix OracleDataRequired error
    // function test_depositCollateral_wrapUSDC() public {
    //     uint256 decimalsFactor = 10 ** (18 - USDC.decimals());

    //     uint256 amount = 1 * decimalsFactor;

    //     deal(address(USDC), ACTOR, amount);

    //     vm.startPrank(ACTOR);

    //     USDC.approve(address(engine), type(uint256).max);

    // uint256 availableMarginBefore =
    //     uint256(perpsMarketProxy.getAvailableMargin(accountId));
    // assertEq(availableMarginBefore, 0);

    //     engine.modifyCollateralWrap({
    //         _accountId: accountId,
    //         _amount: int256(amount),
    //         _tolerance: amount,
    //         _collateral: USDC,
    //         _synthMarketId: USDC_SYNTH_MARKET_ID
    //     });

    //     vm.stopPrank();

    //     // uint256 availableMargin = uint256(perpsMarketProxy.getAvailableMargin(accountId));
    //     // uint256 expectedMargin = SMALLEST_AMOUNT * decimalsFactor;
    //     // assertWithinTolerance(expectedMargin, availableMargin, 2);
    // }

    /// @notice This test is expected to fail because sUSD is not a supported collateral
    function test_depositCollateral_wrapfail_sUSD() public {
        deal(address(sUSD), ACTOR, SMALLER_AMOUNT);

        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        vm.expectRevert();
        engine.modifyCollateralWrap({
            _accountId: accountId,
            _amount: int256(SMALLER_AMOUNT),
            _tolerance: SMALLER_AMOUNT,
            _collateral: sUSD,
            _synthMarketId: 0
        });
    }

    /// @notice This test is expected to fail because USDC is not a supported collateral
    function test_depositCollateral_wrapfail_USDC() public {
        deal(address(USDC), ACTOR, SMALLEST_AMOUNT);

        vm.startPrank(ACTOR);

        USDC.approve(address(engine), type(uint256).max);

        vm.expectRevert();
        engine.modifyCollateralWrap({
            _accountId: accountId,
            _amount: int256(SMALLEST_AMOUNT),
            _tolerance: SMALLEST_AMOUNT,
            _collateral: USDC,
            _synthMarketId: 2
        });
    }

    function test_depositCollateral_ETH() public {
        vm.deal(ACTOR, SMALLER_AMOUNT);

        uint256 availableMarginBefore =
            uint256(perpsMarketProxy.getAvailableMargin(accountId));
        assertEq(availableMarginBefore, 0);

        vm.startPrank(ACTOR);

        engine.depositCollateralETH{value: SMALLER_AMOUNT}({
            _accountId: accountId,
            _amount: SMALLER_AMOUNT,
            _tolerance: SMALLER_AMOUNT
        });

        vm.stopPrank();

        uint256 availableMargin =
            uint256(perpsMarketProxy.getAvailableMargin(accountId));
        uint256 expectedMargin = SMALLER_AMOUNT * ETH_PRICE;
        assertWithinTolerance(expectedMargin, availableMargin, 2);
    }

    function test_depositCollateral_ETH_Fuzz(uint256 amount) public {
        /// @dev amount must be less than max MarketCollateralAmount - currentDepositedCollateral
        vm.assume(amount < MAX_WRAPPABLE_AMOUNT);
        vm.assume(amount > SMALLEST_AMOUNT);
        vm.deal(ACTOR, amount);

        uint256 availableMarginBefore =
            uint256(perpsMarketProxy.getAvailableMargin(accountId));
        assertEq(availableMarginBefore, 0);

        vm.startPrank(ACTOR);

        engine.depositCollateralETH{value: amount}({
            _accountId: accountId,
            _amount: amount,
            _tolerance: amount * 97 / 100
        });

        vm.stopPrank();

        uint256 availableMargin =
            uint256(perpsMarketProxy.getAvailableMargin(accountId));
        uint256 expectedMargin = amount * ETH_PRICE;
        assertWithinTolerance(expectedMargin, availableMargin, 3);
    }

    function test_depositCollateral_ETH_Partial_Fuzz(uint256 amount) public {
        /// @dev amount must be less than max MarketCollateralAmount - currentDepositedCollateral
        vm.assume(amount < MAX_WRAPPABLE_AMOUNT);
        vm.assume(amount > SMALLEST_AMOUNT * 2);
        vm.deal(ACTOR, amount);

        uint256 availableMarginBefore =
            uint256(perpsMarketProxy.getAvailableMargin(accountId));
        assertEq(availableMarginBefore, 0);

        vm.startPrank(ACTOR);

        engine.depositCollateralETH{value: amount}({
            _accountId: accountId,
            _amount: amount - SMALLEST_AMOUNT,
            _tolerance: (amount - SMALLEST_AMOUNT) * 97 / 100
        });

        vm.stopPrank();

        uint256 availableMargin =
            uint256(perpsMarketProxy.getAvailableMargin(accountId));
        uint256 expectedMargin = (amount - SMALLEST_AMOUNT) * ETH_PRICE;
        assertWithinTolerance(expectedMargin, availableMargin, 3);

        assertEq(address(engine).balance, SMALLEST_AMOUNT);
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

    function test_withdrawCollateral_zap() public {
        uint256 decimalsFactor = 10 ** (18 - USDC.decimals());

        deal(address(USDC), ACTOR, SMALLEST_AMOUNT);

        vm.startPrank(ACTOR);

        USDC.approve(address(engine), type(uint256).max);

        // add the collateral
        engine.modifyCollateralZap({
            _accountId: accountId,
            _amount: int256(SMALLEST_AMOUNT),
            _zapMinAmountOut: SMALLEST_AMOUNT - 3
        });

        uint256 postBalanceUSDT = USDC.balanceOf(ACTOR);
        assertEq(postBalanceUSDT, 0);

        uint256 preBalanceUSDC = USDC.balanceOf(ACTOR);
        assertEq(preBalanceUSDC, 0);

        uint256 availableMargin =
            uint256(perpsMarketProxy.getAvailableMargin(accountId));

        // remove the collateral
        engine.modifyCollateralZap({
            _accountId: accountId,
            _amount: -int256(availableMargin),
            _zapMinAmountOut: SMALLEST_AMOUNT - 3
        });

        vm.stopPrank();
        uint256 postBalanceUSDC = USDC.balanceOf(ACTOR);
        uint256 expectedBalance = postBalanceUSDC * decimalsFactor;
        assertWithinTolerance(expectedBalance, availableMargin, 3);
    }

    function test_withdrawCollateral_zap_Unauthorized() public {
        deal(address(USDC), ACTOR, SMALLEST_AMOUNT);

        vm.startPrank(ACTOR);

        USDC.approve(address(engine), type(uint256).max);

        engine.modifyCollateralZap({
            _accountId: accountId,
            _amount: int256(SMALLEST_AMOUNT),
            _zapMinAmountOut: 1
        });

        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(IEngine.Unauthorized.selector));

        engine.modifyCollateralZap({
            _accountId: accountId,
            _amount: -int256(1),
            _zapMinAmountOut: 1
        });
    }

    function test_withdrawCollateral_wrap() public {
        deal(address(WETH), ACTOR, SMALLER_AMOUNT);

        vm.startPrank(ACTOR);

        WETH.approve(address(engine), type(uint256).max);

        engine.modifyCollateralWrap({
            _accountId: accountId,
            _amount: int256(SMALLER_AMOUNT),
            _tolerance: SMALLER_AMOUNT,
            _collateral: WETH,
            _synthMarketId: WETH_SYNTH_MARKET_ID
        });

        uint256 preBalance = WETH.balanceOf(ACTOR);
        assertEq(preBalance, 0);

        engine.modifyCollateralWrap({
            _accountId: accountId,
            _amount: -int256(SMALLER_AMOUNT),
            _tolerance: SMALLER_AMOUNT,
            _collateral: WETH,
            _synthMarketId: WETH_SYNTH_MARKET_ID
        });

        vm.stopPrank();

        uint256 postBalance = WETH.balanceOf(ACTOR);
        assertEq(postBalance, SMALLER_AMOUNT);
    }

    function test_withdrawCollateral_wrap_Unauthorized() public {
        deal(address(WETH), ACTOR, SMALLER_AMOUNT);

        vm.startPrank(ACTOR);

        WETH.approve(address(engine), type(uint256).max);

        engine.modifyCollateralWrap({
            _accountId: accountId,
            _amount: int256(SMALLER_AMOUNT),
            _tolerance: SMALLER_AMOUNT,
            _collateral: WETH,
            _synthMarketId: WETH_SYNTH_MARKET_ID
        });

        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(IEngine.Unauthorized.selector));

        engine.modifyCollateralWrap({
            _accountId: accountId,
            _amount: -int256(SMALLER_AMOUNT),
            _tolerance: SMALLER_AMOUNT,
            _collateral: WETH,
            _synthMarketId: WETH_SYNTH_MARKET_ID
        });
    }

    function test_withdrawCollateral_ETH() public {
        uint256 preBalance = ACTOR.balance;

        vm.deal(ACTOR, SMALLER_AMOUNT);

        vm.startPrank(ACTOR);

        engine.depositCollateralETH{value: SMALLER_AMOUNT}({
            _accountId: accountId,
            _amount: SMALLER_AMOUNT,
            _tolerance: SMALLER_AMOUNT
        });

        uint256 midBalance = ACTOR.balance;
        assertEq(midBalance, 0);

        engine.withdrawCollateralETH({
            _accountId: accountId,
            _amount: int256(SMALLER_AMOUNT),
            _tolerance: SMALLER_AMOUNT
        });

        vm.stopPrank();

        uint256 postBalance = ACTOR.balance;
        assertWithinTolerance(postBalance, preBalance + SMALLER_AMOUNT, 1);
    }

    function test_withdrawCollateral_ETH_Fuzz(uint256 amount) public {
        uint256 preBalance = ACTOR.balance;

        /// @dev amount must be less than max MarketCollateralAmount
        vm.assume(amount < MAX_WRAPPABLE_AMOUNT);
        vm.assume(amount > SMALLEST_AMOUNT);
        vm.deal(ACTOR, amount);

        vm.startPrank(ACTOR);

        engine.depositCollateralETH{value: amount}({
            _accountId: accountId,
            _amount: amount,
            _tolerance: amount * 97 / 100
        });

        uint256 midBalance = ACTOR.balance;
        assertEq(midBalance, 0);

        engine.withdrawCollateralETH({
            _accountId: accountId,
            _amount: int256(amount) - 1,
            _tolerance: amount * 97 / 100
        });

        vm.stopPrank();

        uint256 postBalance = ACTOR.balance;
        assertWithinTolerance(preBalance + amount, postBalance, 3);
    }

    function test_withdrawCollateral_ETH_Unauthorized() public {
        vm.deal(ACTOR, SMALLER_AMOUNT);

        vm.startPrank(ACTOR);

        engine.depositCollateralETH{value: SMALLER_AMOUNT}({
            _accountId: accountId,
            _amount: SMALLER_AMOUNT,
            _tolerance: SMALLER_AMOUNT
        });

        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(IEngine.Unauthorized.selector));

        engine.withdrawCollateralETH({
            _accountId: accountId,
            _amount: int256(SMALLER_AMOUNT),
            _tolerance: SMALLER_AMOUNT
        });
    }

    function test_withdrawCollateral_ETH_transferFailed() public {
        // Create a contract that rejects ETH
        MaliciousReceiver maliciousContract = new MaliciousReceiver();

        vm.deal(address(maliciousContract), SMALLER_AMOUNT);

        vm.startPrank(address(maliciousContract));

        accountId = perpsMarketProxy.createAccount();
        perpsMarketProxy.grantPermission({
            accountId: accountId,
            permission: ADMIN_PERMISSION,
            user: address(engine)
        });

        engine.depositCollateralETH{value: SMALLER_AMOUNT}({
            _accountId: accountId,
            _amount: SMALLER_AMOUNT,
            _tolerance: SMALLER_AMOUNT
        });

        vm.expectRevert(
            abi.encodeWithSelector(IEngine.ETHTransferFailed.selector)
        );

        engine.withdrawCollateralETH({
            _accountId: accountId,
            _amount: int256(SMALLER_AMOUNT),
            _tolerance: SMALLER_AMOUNT
        });
        vm.stopPrank();
    }
}

// Helper contract that rejects ETH transfers
contract MaliciousReceiver {
    receive() external payable {
        revert("I reject ETH");
    }

    function onERC721Received(address, address, uint256, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return 0x150b7a02;
    }
}

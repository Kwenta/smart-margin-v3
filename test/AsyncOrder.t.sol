// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Bootstrap, IPerpsMarketProxy} from "test/utils/Bootstrap.sol";
import {SynthetixMock} from "test/utils/mocks/SynthetixMock.sol";

contract AsyncOrderTest is Bootstrap, SynthetixMock {
    function setUp() public {
        vm.rollFork(GOERLI_BLOCK_NUMBER);
        initializeOptimismGoerli();

        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        vm.stopPrank();
    }
}

contract CommitOrder is AsyncOrderTest {
    function test_commitOrder() public {
        vm.prank(ACTOR);

        (IPerpsMarketProxy.Data memory retOrder, uint256 fees) = engine
            .commitOrder({
            _perpsMarketId: SETH_PERPS_MARKET_ID,
            _accountId: accountId,
            _sizeDelta: 1 ether,
            _settlementStrategyId: 0,
            _acceptablePrice: type(uint256).max,
            _trackingCode: TRACKING_CODE,
            _referrer: REFERRER
        });

        // retOrder
        assertTrue(retOrder.settlementTime != 0);
        assertTrue(retOrder.request.marketId == SETH_PERPS_MARKET_ID);
        assertTrue(retOrder.request.accountId == accountId);
        assertTrue(retOrder.request.sizeDelta == 1 ether);
        assertTrue(retOrder.request.settlementStrategyId == 0);
        assertTrue(retOrder.request.acceptablePrice == type(uint256).max);
        assertTrue(retOrder.request.trackingCode == TRACKING_CODE);
        assertTrue(retOrder.request.referrer == REFERRER);

        // fees
        assertTrue(fees != 0);
    }

    function test_commitOrder_invalid_market() public {
        vm.prank(ACTOR);

        vm.expectRevert(
            abi.encodeWithSelector(
                InvalidMarket.selector, INVALID_PERPS_MARKET_ID
            )
        );

        engine.commitOrder({
            _perpsMarketId: INVALID_PERPS_MARKET_ID,
            _accountId: accountId,
            _sizeDelta: 1 ether,
            _settlementStrategyId: 0,
            _acceptablePrice: type(uint256).max,
            _trackingCode: TRACKING_CODE,
            _referrer: REFERRER
        });
    }

    function test_commitOrder_insufficient_collateral() public {
        int128 sizeDelta = 1000 ether;

        uint256 requiredMargin = perpsMarketProxy.requiredMarginForOrder(
            accountId, SETH_PERPS_MARKET_ID, sizeDelta
        );

        int256 availableMargin = perpsMarketProxy.getAvailableMargin(accountId);

        assertGt(requiredMargin, uint256(availableMargin));

        vm.prank(ACTOR);

        vm.expectRevert(
            abi.encodeWithSelector(
                InsufficientMargin.selector, AMOUNT, requiredMargin
            )
        );

        engine.commitOrder({
            _perpsMarketId: SETH_PERPS_MARKET_ID,
            _accountId: accountId,
            _sizeDelta: sizeDelta,
            _settlementStrategyId: 0,
            _acceptablePrice: type(uint256).max,
            _trackingCode: TRACKING_CODE,
            _referrer: REFERRER
        });
    }
}

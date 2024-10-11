// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

import {Bootstrap} from "test/utils/Bootstrap.sol";
import {IEngine} from "src/interfaces/IEngine.sol";
import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";
import {SynthetixMock} from "test/utils/mocks/SynthetixMock.sol";

contract AsyncOrderTest is Bootstrap, SynthetixMock {
    function setUp() public {
        vm.rollFork(ARBITRUM_BLOCK_NUMBER);
        initializeArbitrum();

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

/// @custom:todo rewrite commented tests with hardhat
/// cause : InvalidFEOpcode when calling getPricesInWei on Arbitrum
contract CommitOrder is AsyncOrderTest {
    // function test_commitOrder() public {
    //     vm.prank(ACTOR);

    //     (IPerpsMarketProxy.Data memory retOrder, uint256 fees) = engine
    //         .commitOrder({
    //         _perpsMarketId: SETH_PERPS_MARKET_ID,
    //         _accountId: accountId,
    //         _sizeDelta: SIZE_DELTA,
    //         _settlementStrategyId: SETTLEMENT_STRATEGY_ID,
    //         _acceptablePrice: ACCEPTABLE_PRICE_LONG,
    //         _trackingCode: TRACKING_CODE,
    //         _referrer: REFERRER
    //     });

    //     assertTrue(retOrder.settlementTime != 0);
    //     assertTrue(retOrder.request.marketId == SETH_PERPS_MARKET_ID);
    //     assertTrue(retOrder.request.accountId == accountId);
    //     assertTrue(retOrder.request.sizeDelta == SIZE_DELTA);
    //     assertTrue(
    //         retOrder.request.settlementStrategyId == SETTLEMENT_STRATEGY_ID
    //     );
    //     assertTrue(retOrder.request.acceptablePrice == ACCEPTABLE_PRICE_LONG);
    //     assertTrue(retOrder.request.trackingCode == TRACKING_CODE);
    //     assertTrue(retOrder.request.referrer == REFERRER);

    //     assertTrue(fees != 0);
    // }

    // function test_commitOrder_invalid_market() public {
    //     vm.prank(ACTOR);

    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             InvalidMarket.selector, INVALID_PERPS_MARKET_ID
    //         )
    //     );

    //     engine.commitOrder({
    //         _perpsMarketId: INVALID_PERPS_MARKET_ID,
    //         _accountId: accountId,
    //         _sizeDelta: SIZE_DELTA,
    //         _settlementStrategyId: SETTLEMENT_STRATEGY_ID,
    //         _acceptablePrice: ACCEPTABLE_PRICE_LONG,
    //         _trackingCode: TRACKING_CODE,
    //         _referrer: REFERRER
    //     });
    // }

    // function test_commitOrder_insufficient_collateral() public {
    //     vm.prank(ACTOR);

    //     try engine.commitOrder({
    //         _perpsMarketId: SETH_PERPS_MARKET_ID,
    //         _accountId: accountId,
    //         _sizeDelta: SIZE_DELTA * SIZE_DELTA,
    //         _settlementStrategyId: SETTLEMENT_STRATEGY_ID,
    //         _acceptablePrice: ACCEPTABLE_PRICE_LONG,
    //         _trackingCode: TRACKING_CODE,
    //         _referrer: REFERRER
    //     }) {} catch (bytes memory reason) {
    //         assertEq(bytes4(reason), InsufficientMargin.selector);
    //     }
    // }

    // function test_commitOrder_Unauthorized() public {
    //     vm.prank(BAD_ACTOR);

    //     vm.expectRevert(abi.encodeWithSelector(IEngine.Unauthorized.selector));

    //     engine.commitOrder({
    //         _perpsMarketId: SETH_PERPS_MARKET_ID,
    //         _accountId: accountId,
    //         _sizeDelta: SIZE_DELTA,
    //         _settlementStrategyId: SETTLEMENT_STRATEGY_ID,
    //         _acceptablePrice: ACCEPTABLE_PRICE_LONG,
    //         _trackingCode: TRACKING_CODE,
    //         _referrer: REFERRER
    //     });
    // }
}

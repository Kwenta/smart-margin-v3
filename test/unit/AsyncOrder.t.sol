// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Bootstrap, IPerpsMarketProxy} from "test/utils/Bootstrap.sol";

contract AsyncOrderTest is Bootstrap {
    function setUp() public {
        vm.rollFork(GOERLI_BLOCK_NUMBER);
        initializeOptimismGoerli();
    }
}

contract CommitOrder is AsyncOrderTest {
    function test_commitOrder() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

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

        vm.stopPrank();

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

    /// @cutsoom:todo test commitOrder: Market that does not exist
    /// @custom:todo test commitOrder: Market that is paused
    /// @custom:todo test commitOrder: Account does not have enough collateral/margin
    /// @custom:todo test commitOrder: Position size exceeds max leverage
}

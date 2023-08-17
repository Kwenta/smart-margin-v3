// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Bootstrap} from "test/utils/Bootstrap.sol";

contract MulticallableTest is Bootstrap {
    function setUp() public {
        vm.rollFork(GOERLI_BLOCK_NUMBER);
        initializeOptimismGoerli();
    }

    function test_multicall_depositCollateral_commitOrder() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(
            engine.modifyCollateral.selector,
            accountId,
            SUSD_SPOT_MARKET_ID,
            int256(AMOUNT)
        );
        data[1] = abi.encodeWithSelector(
            engine.commitOrder.selector,
            SETH_PERPS_MARKET_ID,
            accountId,
            1 ether,
            0,
            type(uint256).max,
            REFERRER
        );

        engine.multicall(data);
    }
}
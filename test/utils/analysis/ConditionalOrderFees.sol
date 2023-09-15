// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Bootstrap, console2} from "test/utils/Bootstrap.sol";

contract ConditionalOrderTest is Bootstrap {
    function setUp() public {
        vm.rollFork(GOERLI_BLOCK_NUMBER);
        initializeOptimismGoerli();
    }

    function plot_chart() public view {
        for (uint256 i = 1; i <= 700; i++) {
            uint256 sizeDelta = i * 1e17;
            (uint256 orderFees,) = perpsMarketProxy.computeOrderFees({
                marketId: SETH_PERPS_MARKET_ID,
                sizeDelta: int128(int256(sizeDelta))
            });

            uint256 conditional_order_fee =
                orderFees * engineExposed.FEE_SCALING_FACTOR() / 10_000;

            if (conditional_order_fee < engineExposed.LOWER_FEE_CAP()) {
                console2.log("%s,", engineExposed.LOWER_FEE_CAP() / 1e18);
            } else if (conditional_order_fee > engineExposed.UPPER_FEE_CAP()) {
                console2.log("%s,", engineExposed.UPPER_FEE_CAP() / 1e18);
            } else {
                console2.log("%s,", conditional_order_fee / 1e18);
            }
        }
    }
}

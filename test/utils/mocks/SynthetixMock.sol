// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract SynthetixMock is Test {
    function mock_computeOrderFees(
        address perpsMarketProxy,
        uint128 marketId,
        int128 sizeDelta,
        uint256 orderFees,
        uint256 fillPrice
    ) public {
        vm.mockCall(
            perpsMarketProxy,
            abi.encodeWithSelector(
                IPerpsMarketProxy.computeOrderFees.selector, marketId, sizeDelta
            ),
            abi.encode(orderFees, fillPrice)
        );
    }

    function mock_getOpenPosition(
        address perpsMarketProxy,
        uint128 accountId,
        uint128 marketId,
        int128 positionSize
    ) public {
        vm.mockCall(
            perpsMarketProxy,
            abi.encodeWithSelector(
                IPerpsMarketProxy.getOpenPosition.selector, accountId, marketId
            ),
            abi.encode(0, 0, positionSize)
        );
    }
}

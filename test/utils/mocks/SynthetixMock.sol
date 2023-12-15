// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {IPerpsMarketProxy} from "test/utils/interfaces/IPerpsMarketProxy.sol";
import {Test} from "lib/forge-std/src/Test.sol";

/// @title Mocking contract for mocking Synthetix v3 functionality for testing purposes
/// @author JaredBorders (jaredborders@pm.me)
contract SynthetixMock is Test {
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

    function mock_getMaxMarketSize(
        address marketConfigurationModule,
        uint128 marketId,
        uint256 maxMarketSize
    ) public {
        vm.mockCall(
            marketConfigurationModule,
            abi.encodeWithSelector(
                IPerpsMarketProxy.getMaxMarketSize.selector, marketId
            ),
            abi.encode(maxMarketSize)
        );
    }

    function mock_getAccountOwner(
        address perpsMarketProxy,
        uint128 accountId,
        address owner
    ) public {
        vm.mockCall(
            perpsMarketProxy,
            abi.encodeWithSelector(
                IPerpsMarketProxy.getAccountOwner.selector, accountId
            ),
            abi.encode(owner)
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {EIP7412} from "src/utils/EIP7412.sol";
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

    function mock_fulfillOracleQuery(
        address EIP7412Implementer,
        bytes calldata signedOffchainData
    ) public {
        vm.mockCall(
            EIP7412Implementer,
            abi.encodeWithSelector(
                EIP7412.fulfillOracleQuery.selector, signedOffchainData
            ),
            abi.encode()
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Bootstrap} from "test/utils/Bootstrap.sol";
import {IEngine} from "src/interfaces/IEngine.sol";

contract ConditionalOrderTest is Bootstrap {
    function setUp() public {
        vm.rollFork(GOERLI_BLOCK_NUMBER);
        initializeOptimismGoerli();
    }
}

contract VerificationTest is ConditionalOrderTest {
    function test_verifyCondtionalOrder_verified() public {
        bytes[] memory conditions = new bytes[](1);
        conditions[0] = isTimestampAfter(0);

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            signer: address(0),
            nonce: 0,
            requireVerified: true,
            marketId: 0,
            accountId: 0,
            sizeDelta: 0,
            settlementStrategyId: 0,
            acceptablePrice: 0,
            trustedExecutor: address(this),
            conditions: conditions
        });

        bool isVerified = engine.verifyConditions(co);

        assertTrue(isVerified);
    }

    function test_verifyCondtionalOrder_not_verified() public {
        bytes[] memory conditions = new bytes[](1);
        conditions[0] = isTimestampAfter(type(uint256).max);

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            signer: address(0),
            nonce: 0,
            requireVerified: true,
            marketId: 0,
            accountId: 0,
            sizeDelta: 0,
            settlementStrategyId: 0,
            acceptablePrice: 0,
            trustedExecutor: address(0),
            conditions: conditions
        });

        bool isVerified = engine.verifyConditions(co);

        assertFalse(isVerified);
    }
}

contract ConditionsTest is ConditionalOrderTest {}

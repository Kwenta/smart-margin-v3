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

contract Execute is ConditionalOrderTest {
/// @custom:todo canExecute !verifySigner()
/// @custom:todo canExecute !verifySignature()
/// @custom:todo canExecute !verifyConditions()
/// @custom:todo canExecute !trustedExecutor
/// @custom:todo canExecute when account has enough gas
/// @custom:todo canExecute when account doesnt have enough gas
/// @custom:todo test order is committed
/// @custom:todo test no replays (i.e. nonce is used)
/// @custom:todo test when order committed results in error (exceeds leverage after fee taken by executor)
/// @custom:todo test when order committed results in error (other edge cases)
/// @custom:todo test error CannotExecuteOrder()
}

contract VerifySigner is ConditionalOrderTest {}

contract VerifySignature is ConditionalOrderTest {}

contract VerifyConditions is ConditionalOrderTest {
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

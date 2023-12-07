// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Bootstrap} from "test/utils/Bootstrap.sol";
import {
    ERC2771Context, TrustedForwarder
} from "src/utils/TrustedForwarder.sol";
import {
    MockCallee, MockCalleeWithContext
} from "test/utils/mocks/MockCallee.sol";
import {EIP7412Mock} from "test/utils/mocks/EIP7412Mock.sol";

contract TrustedForwarderTest is Bootstrap {
    TrustedForwarder trustedForwarder;
    MockCallee mockCallee;
    MockCalleeWithContext mockCalleeWithContext;
    EIP7412Mock eip7412Mock;

    function setUp() public {
        vm.rollFork(GOERLI_BLOCK_NUMBER);
        initializeOptimismGoerli();

        trustedForwarder = TrustedForwarder(engine.trustedForwarder());

        mockCallee = new MockCallee();
        mockCalleeWithContext =
            new MockCalleeWithContext(address(trustedForwarder));
        eip7412Mock = new EIP7412Mock();
    }
}

contract Aggregate3Value is TrustedForwarderTest {
    /// @custom:notation aggregate3Value AKA av3

    function test_a3v() public {
        TrustedForwarder.Call3Value[] memory calls =
            new TrustedForwarder.Call3Value[](1);
        calls[0] = TrustedForwarder.Call3Value(
            address(mockCalleeWithContext), // target
            true, // requireSuccess
            0, // value
            abi.encodeWithSelector(
                MockCalleeWithContext.thisMethodSucceeds.selector
            ) // callData
        );

        TrustedForwarder.Result[] memory results =
            trustedForwarder.aggregate3Value(calls);

        for (uint256 i = 0; i < results.length; i++) {
            assertTrue(results[i].success);
            assertTrue(results[i].returnData.length == 0);
        }
    }

    function test_a3v_empty() public {
        TrustedForwarder.Call3Value[] memory calls =
            new TrustedForwarder.Call3Value[](0);

        TrustedForwarder.Result[] memory results =
            trustedForwarder.aggregate3Value(calls);

        assertTrue(results.length == 0);
    }

    function test_a3v_TargetNotTrusted() public {
        /// @custom:todo
    }

    function test_a3v_MismatchedValue() public {
        /// @custom:todo
    }

    function test_a3v_requireSuccess() public {
        /// @custom:todo

        // does require success and succeeds
        // does require success and reverts
        // does not require success and succeeds
        // does not require success and reverts
    }

    function test_a3v_value() public {
        /// @custom:todo

        // msg.value is zero
        // msg.value is non-zero and is not forwarded
        // msg.value is non-zero and is forwarded
        // msg.value exceeds what caller possesses
    }

    function test_a3v_callData() public {
        /// @custom:todo

        // callData is empty
        // callData is not empty
    }

    function test_a3v_result() public {
        /// @custom:todo

        // result.returnData is empty
        // result.returnData is not empty
    }
}

contract Context is TrustedForwarderTest {
    function test_context_trustedForwarder() public {
        assertTrue(engine.trustedForwarder() == address(trustedForwarder));

        assertTrue(
            mockCalleeWithContext.trustedForwarder()
                == address(trustedForwarder)
        );
    }

    function test_context_msgSender() public {
        /// @custom:todo
    }

    function test_context_msgData() public {
        /// @custom:todo
    }
}

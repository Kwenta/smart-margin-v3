// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Bootstrap} from "test/utils/Bootstrap.sol";
import {
    ERC2771Context, TrustedForwarder
} from "src/utils/TrustedForwarder.sol";
import {
    MockCallee, MockCalleeWithContext
} from "test/utils/mocks/MockCallee.sol";
import {
    EIP7412Mock,
    EIP7412MockRefund,
    EIP7412MockRevert
} from "test/utils/mocks/EIP7412Mock.sol";
import {EIP7412} from "src/utils/EIP7412.sol";
import {ETHSink} from "test/utils/mocks/ETHSink.sol";

contract TrustedForwarderTest is Bootstrap {
    TrustedForwarder trustedForwarder;
    MockCallee mockCallee;
    MockCalleeWithContext mockCalleeWithContext;
    EIP7412Mock eip7412Mock;
    EIP7412MockRefund eip7412MockRefund;
    EIP7412MockRevert eip7412MockRevert;
    ETHSink ethSink;

    function setUp() public {
        vm.rollFork(GOERLI_BLOCK_NUMBER);
        initializeOptimismGoerli();

        trustedForwarder = TrustedForwarder(payable(engine.trustedForwarder()));

        mockCallee = new MockCallee();
        mockCalleeWithContext =
            new MockCalleeWithContext(address(trustedForwarder));

        eip7412Mock = new EIP7412Mock();
        eip7412MockRefund = new EIP7412MockRefund();
        eip7412MockRevert = new EIP7412MockRevert();

        ethSink = new ETHSink();
    }
}

contract Aggregate is TrustedForwarderTest {
    event Success(); // EIP7412Mock

    function test_aggregate_single() public {
        TrustedForwarder.Call[] memory calls = new TrustedForwarder.Call[](1);
        calls[0] = TrustedForwarder.Call(
            address(mockCalleeWithContext), // target
            0, // value
            abi.encodeWithSelector(
                MockCalleeWithContext.thisMethodSucceeds.selector
            ) // callData
        );

        bytes[] memory results = trustedForwarder.aggregate(calls);

        for (uint256 i = 0; i < results.length; i++) {
            assertTrue(results[i].length == 0);
        }
    }

    function test_aggregate_multiple() public {
        uint256 callValue = 3 ether;
        uint256 msgValue = 9 ether;

        TrustedForwarder.Call[] memory calls = new TrustedForwarder.Call[](3);
        calls[0] = TrustedForwarder.Call(
            address(mockCalleeWithContext), // target
            callValue, // value
            abi.encodeWithSelector(MockCalleeWithContext.lockEth.selector) // callData
        );
        calls[1] = TrustedForwarder.Call(
            address(mockCalleeWithContext), // target
            callValue, // value
            abi.encodeWithSelector(MockCalleeWithContext.lockEth.selector) // callData
        );
        calls[2] = TrustedForwarder.Call(
            address(mockCalleeWithContext), // target
            callValue, // value
            abi.encodeWithSelector(MockCalleeWithContext.lockEth.selector) // callData
        );

        bytes[] memory results =
            trustedForwarder.aggregate{value: msgValue}(calls);

        for (uint256 i = 0; i < results.length; i++) {
            assertTrue(abi.decode(results[i], (uint256)) == callValue);
        }
    }

    function test_aggregate_empty() public {
        TrustedForwarder.Call[] memory calls = new TrustedForwarder.Call[](0);

        bytes[] memory results = trustedForwarder.aggregate(calls);

        for (uint256 i = 0; i < results.length; i++) {
            assertTrue(results[i].length == 0);
        }
    }

    function test_aggregate_TargetNotTrusted() public {
        // MockCallee has no context and therefore does not
        // nor could not trust the forwarder
        TrustedForwarder.Call[] memory calls = new TrustedForwarder.Call[](1);
        calls[0] = TrustedForwarder.Call(
            address(mockCallee), // target (known not to be trusted)
            0, // value
            abi.encodeWithSelector(MockCallee.thisMethodSucceeds.selector) // callData
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                TrustedForwarder.TargetNotTrusted.selector, address(mockCallee)
            )
        );

        trustedForwarder.aggregate(calls);
    }

    function test_aggregate_MismatchedValue_single() public {
        uint256 callValue = 1 ether;
        uint256 msgValue = 2 ether;

        TrustedForwarder.Call[] memory calls = new TrustedForwarder.Call[](1);
        calls[0] = TrustedForwarder.Call(
            address(mockCalleeWithContext), // target
            callValue, // value
            abi.encodeWithSelector(MockCalleeWithContext.lockEth.selector) // callData
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                TrustedForwarder.MismatchedValue.selector, callValue, msgValue
            )
        );

        trustedForwarder.aggregate{value: msgValue}(calls);
    }

    function test_aggregate_MismatchedValue_multiple() public {
        uint256 callValue = 1 ether;
        uint256 msgValue = 9 ether;

        TrustedForwarder.Call[] memory calls = new TrustedForwarder.Call[](3);
        calls[0] = TrustedForwarder.Call(
            address(mockCalleeWithContext), // target
            callValue, // value
            abi.encodeWithSelector(MockCalleeWithContext.lockEth.selector) // callData
        );
        calls[1] = TrustedForwarder.Call(
            address(mockCalleeWithContext), // target
            callValue, // value
            abi.encodeWithSelector(MockCalleeWithContext.lockEth.selector) // callData
        );
        calls[2] = TrustedForwarder.Call(
            address(mockCalleeWithContext), // target
            callValue, // value
            abi.encodeWithSelector(MockCalleeWithContext.lockEth.selector) // callData
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                TrustedForwarder.MismatchedValue.selector,
                (callValue * 3),
                msgValue
            )
        );

        trustedForwarder.aggregate{value: msgValue}(calls);
    }

    function test_aggregate_value_single(uint256 fuzzValue) public {
        bytes[] memory results;
        TrustedForwarder.Call[] memory calls = new TrustedForwarder.Call[](1);
        calls[0] = TrustedForwarder.Call(
            address(mockCalleeWithContext), // target
            fuzzValue, // value
            abi.encodeWithSelector(MockCalleeWithContext.lockEth.selector) // callData
        );

        if (fuzzValue == 0) {
            results = trustedForwarder.aggregate{value: fuzzValue}(calls);
        } else if (fuzzValue > address(this).balance) {
            // EvmError: Revert <- EvmError: OutOfFund
            vm.expectRevert();
            results = trustedForwarder.aggregate{value: fuzzValue}(calls);
        } else if (fuzzValue <= address(this).balance) {
            results = trustedForwarder.aggregate{value: fuzzValue}(calls);
        } else {
            revert("fuzzValue is NaN");
        }

        for (uint256 i = 0; i < results.length; i++) {
            assertTrue(abi.decode(results[i], (uint256)) == fuzzValue);
        }
    }

    function test_aggregate_value_multiple() public {
        uint256 callValue = 1 ether;
        uint256 msgValue = 3 ether;

        bytes[] memory results;
        TrustedForwarder.Call[] memory calls = new TrustedForwarder.Call[](3);
        calls[0] = TrustedForwarder.Call(
            address(mockCalleeWithContext), // target
            callValue, // value
            abi.encodeWithSelector(MockCalleeWithContext.lockEth.selector) // callData
        );
        calls[1] = TrustedForwarder.Call(
            address(mockCalleeWithContext), // target
            callValue, // value
            abi.encodeWithSelector(MockCalleeWithContext.lockEth.selector) // callData
        );
        calls[2] = TrustedForwarder.Call(
            address(mockCalleeWithContext), // target
            callValue + 1 wei, // value (1 wei more than total msg.value)
            abi.encodeWithSelector(MockCalleeWithContext.lockEth.selector) // callData
        );

        // EvmError: Revert <- EvmError: OutOfFund
        /// @dev we do not expect a MismatchedValue error here because the
        /// aggregate function is trying to spend more than the msg.value
        /// allocated to it, which results in an OutOfFund EvmError
        vm.expectRevert();

        results = trustedForwarder.aggregate{value: msgValue}(calls);
    }

    function test_aggregate_result() public {
        uint256 callValue1 = 0;
        uint256 callValue2 = 2 ether;
        uint256 callValue3 = 3 ether;

        bytes[] memory results;
        TrustedForwarder.Call[] memory calls = new TrustedForwarder.Call[](3);
        calls[0] = TrustedForwarder.Call(
            address(mockCalleeWithContext), // target
            callValue1, // value
            abi.encodeWithSelector(
                MockCalleeWithContext.thisMethodSucceeds.selector
            ) // callData
        );
        calls[1] = TrustedForwarder.Call(
            address(mockCalleeWithContext), // target
            callValue2, // value
            abi.encodeWithSelector(MockCalleeWithContext.lockEth.selector) // callData
        );
        calls[2] = TrustedForwarder.Call(
            address(mockCalleeWithContext), // target
            callValue3, // value
            abi.encodeWithSelector(
                MockCalleeWithContext.sendEthValueTo.selector, address(ethSink)
            ) // callData
        );

        results = trustedForwarder.aggregate{
            value: (callValue1 + callValue2 + callValue3)
        }(calls);

        assertTrue(results[0].length == 0);
        assertTrue(abi.decode(results[1], (uint256)) == callValue2);
        assertTrue(results[0].length == 0);
    }

    function test_aggregate_refund() public {
        TrustedForwarder.Call[] memory calls = new TrustedForwarder.Call[](1);
        calls[0] = TrustedForwarder.Call(
            address(mockCalleeWithContext), // target
            1 ether, // value
            abi.encodeWithSelector(MockCalleeWithContext.sendEthBack.selector) // callData
        );

        vm.expectRevert();

        // trusted forwarder does not support refunds
        trustedForwarder.aggregate{value: 1 ether}(calls);
    }

    function test_aggregate_EIP7412Mock(bytes calldata signedOffchainData)
        public
    {
        TrustedForwarder.Call[] memory calls = new TrustedForwarder.Call[](1);

        calls[0] = TrustedForwarder.Call(
            address(engine), // target
            1 ether, // value
            abi.encodeWithSelector(
                EIP7412.fulfillOracleQuery.selector,
                payable(address(eip7412Mock)),
                signedOffchainData
            ) // callData
        );

        vm.expectEmit(true, true, true, true);
        emit Success();

        bytes[] memory results =
            trustedForwarder.aggregate{value: 1 ether}(calls);

        assertTrue(results[0].length == 0);
    }

    function test_aggregate_EIP7412Mock_fail(bytes calldata signedOffchainData)
        public
    {
        TrustedForwarder.Call[] memory calls = new TrustedForwarder.Call[](1);

        calls[0] = TrustedForwarder.Call(
            address(engine), // target
            0, // value
            abi.encodeWithSelector(
                EIP7412.fulfillOracleQuery.selector,
                payable(address(eip7412Mock)),
                signedOffchainData
            ) // callData
        );

        vm.expectRevert("EIP7412Mock");

        trustedForwarder.aggregate(calls);
    }

    function test_aggregate_EIP7412MockRefund(bytes calldata signedOffchainData)
        public
    {
        TrustedForwarder.Call[] memory calls = new TrustedForwarder.Call[](1);

        calls[0] = TrustedForwarder.Call(
            address(engine), // target
            1 ether, // value
            abi.encodeWithSelector(
                EIP7412.fulfillOracleQuery.selector,
                payable(address(eip7412MockRefund)),
                signedOffchainData
            ) // callData
        );

        vm.expectRevert("EIP7412MockRefund");

        // engine's EIP7412 implementation does not support refunds
        trustedForwarder.aggregate{value: 1 ether}(calls);
    }

    function test_aggregate_EIP7412MockRevert(bytes calldata signedOffchainData)
        public
    {
        TrustedForwarder.Call[] memory calls = new TrustedForwarder.Call[](1);

        calls[0] = TrustedForwarder.Call(
            address(engine), // target
            1 ether, // value
            abi.encodeWithSelector(
                EIP7412.fulfillOracleQuery.selector,
                payable(address(eip7412MockRevert)),
                signedOffchainData
            ) // callData
        );

        vm.expectRevert("EIP7412MockRevert");

        trustedForwarder.aggregate{value: 1 ether}(calls);
    }

    function test_aggregate_EIP7412_multiple(bytes calldata signedOffchainData)
        public
    {
        TrustedForwarder.Call[] memory calls = new TrustedForwarder.Call[](2);

        // successful call
        calls[0] = TrustedForwarder.Call(
            address(engine), // target
            1 ether, // value
            abi.encodeWithSelector(
                EIP7412.fulfillOracleQuery.selector,
                payable(address(eip7412Mock)),
                signedOffchainData
            ) // callData
        );

        // unsuccessful call
        calls[0] = TrustedForwarder.Call(
            address(engine), // target
            0, // value
            abi.encodeWithSelector(
                EIP7412.fulfillOracleQuery.selector,
                payable(address(eip7412Mock)),
                signedOffchainData
            ) // callData
        );

        vm.expectRevert("EIP7412Mock");

        trustedForwarder.aggregate{value: 1 ether}(calls);
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
}

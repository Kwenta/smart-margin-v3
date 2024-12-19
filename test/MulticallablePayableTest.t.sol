// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

import {Bootstrap} from "test/utils/Bootstrap.sol";
import {MockMulticallablePayable as MP} from
    "./utils/mocks/MockMulticallablePayable.sol";
import {EIP7412Mock} from "test/utils/mocks/EIP7412Mock.sol";
import {IEngine} from "src/interfaces/IEngine.sol";
import {EIP7412} from "src/utils/EIP7412.sol";

/// @author Solady
contract MulticallablePayableTest is Bootstrap {
    MP mp;
    EIP7412Mock eip7412Mock;

    function setUp() public {
        vm.rollFork(BASE_BLOCK_NUMBER);
        initializeBase();

        mp = new MP();
        eip7412Mock = new EIP7412Mock();
    }
}

contract Multicall is MulticallablePayableTest {
    function testMulticallableRevertWithMessage(string memory revertMessage)
        public
    {
        bytes[] memory data = new bytes[](1);
        data[0] =
            abi.encodeWithSelector(MP.revertsWithString.selector, revertMessage);
        vm.expectRevert(bytes(revertMessage));
        mp.multicall(data);
    }

    function testMulticallableRevertWithMessage() public {
        testMulticallableRevertWithMessage("Milady");
    }

    function testMulticallableRevertWithCustomError() public {
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(MP.revertsWithCustomError.selector);
        vm.expectRevert(MP.CustomError.selector);
        mp.multicall(data);
    }

    function testMulticallableRevertWithNothing() public {
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(MP.revertsWithNothing.selector);
        vm.expectRevert();
        mp.multicall(data);
    }

    function testMulticallableReturnDataIsProperlyEncoded(
        uint256 a0,
        uint256 b0,
        uint256 a1,
        uint256 b1
    ) public {
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(MP.returnsTuple.selector, a0, b0);
        data[1] = abi.encodeWithSelector(MP.returnsTuple.selector, a1, b1);
        bytes[] memory returnedData = mp.multicall(data);
        MP.Tuple memory t0 = abi.decode(returnedData[0], (MP.Tuple));
        MP.Tuple memory t1 = abi.decode(returnedData[1], (MP.Tuple));
        assertEq(t0.a, a0);
        assertEq(t0.b, b0);
        assertEq(t1.a, a1);
        assertEq(t1.b, b1);
    }

    function testMulticallableReturnDataIsProperlyEncoded(
        string memory sIn0,
        string memory sIn1,
        uint256 n
    ) public {
        n = n % 2;
        bytes[] memory dataIn = new bytes[](n);
        if (n > 0) {
            dataIn[0] = abi.encodeWithSelector(MP.returnsString.selector, sIn0);
        }
        if (n > 1) {
            dataIn[1] = abi.encodeWithSelector(MP.returnsString.selector, sIn1);
        }
        bytes[] memory dataOut = mp.multicall(dataIn);
        if (n > 0) {
            assertEq(abi.decode(dataOut[0], (string)), sIn0);
        }
        if (n > 1) {
            assertEq(abi.decode(dataOut[1], (string)), sIn1);
        }
    }

    function testMulticallableReturnDataIsProperlyEncoded() public {
        testMulticallableReturnDataIsProperlyEncoded(0, 1, 2, 3);
    }

    function testMulticallableBenchmark() public {
        unchecked {
            bytes[] memory data = new bytes[](10);
            for (uint256 i; i != data.length; ++i) {
                data[i] =
                    abi.encodeWithSelector(MP.returnsTuple.selector, i, i + 1);
            }
            bytes[] memory returnedData = mp.multicall(data);
            assertEq(returnedData.length, data.length);
        }
    }

    function testMulticallableOriginalBenchmark() public {
        unchecked {
            bytes[] memory data = new bytes[](10);
            for (uint256 i; i != data.length; ++i) {
                data[i] =
                    abi.encodeWithSelector(MP.returnsTuple.selector, i, i + 1);
            }
            bytes[] memory returnedData = mp.multicallOriginal(data);
            assertEq(returnedData.length, data.length);
        }
    }

    function testMulticallableWithNoData() public {
        bytes[] memory data = new bytes[](0);
        assertEq(mp.multicall(data).length, 0);
    }

    function testMulticallablePreservesMsgSender() public {
        address caller = address(uint160(0xbeef));
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(MP.returnsSender.selector);
        vm.prank(caller);
        address returnedAddress = abi.decode(mp.multicall(data)[0], (address));
        assertEq(caller, returnedAddress);
    }
}

contract MulticallableEngine is MulticallablePayableTest {
    function test_multicall_engine_fulfillOracleQuery_modifyCollateral()
        public
    {
        bytes[] memory data = new bytes[](2);

        vm.deal(ACTOR, AMOUNT);
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        // call mock oracle to simulate payable function call
        data[0] = abi.encodeWithSelector(
            EIP7412.fulfillOracleQuery.selector,
            address(eip7412Mock),
            abi.encodePacked("")
        );

        // call engine to modify collateral
        data[1] = abi.encodeWithSelector(
            IEngine.modifyCollateral.selector,
            accountId,
            SUSD_SPOT_MARKET_ID,
            int256(AMOUNT)
        );

        engine.multicall{value: 1 wei}(data);

        vm.stopPrank();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {MarginEngine} from "src/MarginEngine.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract MarginEngineTest is Test, MarginEngine {
    MarginEngine marginEngine;

    function setUp() public {
        marginEngine = new MarginEngine();
    }
}

contract Multicallable is MarginEngineTest {
    function test_Multicallable_CreateAccount() public {
        uint256 desiredAccountId = 19;
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(
            MarginEngine.createAccount.selector, desiredAccountId
        );
        vm.expectEmit(true, true, true, true);
        emit AccountCreated(desiredAccountId);
        marginEngine.multicall(data);
    }

    function test_Multicallable_DepositMargin() public {
        uint256 accountId = 19;
        address marginType = address(0x1);
        uint256 amount = 1 ether;
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(
            MarginEngine.depositMargin.selector, accountId, marginType, amount
        );
        vm.expectEmit(true, true, true, true);
        emit MarginDeposited(accountId, marginType, amount);
        marginEngine.multicall(data);
    }

    function test_Multicallable_WithdrawMargin() public {
        uint256 accountId = 19;
        address marginType = address(0x1);
        uint256 amount = 1 ether;
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(
            MarginEngine.withdrawMargin.selector, accountId, marginType, amount
        );
        vm.expectEmit(true, true, true, true);
        emit MarginWithdrawn(accountId, marginType, amount);
        marginEngine.multicall(data);
    }

    function test_Multicallable_DepositCollateral() public {
        uint256 accountId = 19;
        address marginType = address(0x1);
        uint256 amount = 1 ether;
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(
            MarginEngine.depositCollateral.selector,
            accountId,
            marginType,
            amount
        );
        vm.expectEmit(true, true, true, true);
        emit CollateralDeposited(accountId, marginType, amount);
        marginEngine.multicall(data);
    }

    function test_Multicallable_WithdrawCollateral() public {
        uint256 accountId = 19;
        address marginType = address(0x1);
        uint256 amount = 1 ether;
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(
            MarginEngine.withdrawCollateral.selector,
            accountId,
            marginType,
            amount
        );
        vm.expectEmit(true, true, true, true);
        emit CollateralWithdrawn(accountId, marginType, amount);
        marginEngine.multicall(data);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Bootstrap} from "test/utils/Bootstrap.sol";
import {IEngine} from "src/interfaces/IEngine.sol";
import {SynthetixMock} from "test/utils/mocks/SynthetixMock.sol";

contract CantReceiveEth {}

contract EthManagementTest is Bootstrap, SynthetixMock {
    function setUp() public {
        vm.rollFork(GOERLI_BLOCK_NUMBER);
        initializeOptimismGoerli();
    }
}

contract Deposit is EthManagementTest {
    event EthDeposit(uint128 indexed accountId, uint256 amount);

    function test_depositEth() public {
        assertEq(engine.ethBalances(accountId), 0);
        assertEq(address(engine).balance, 0);

        engine.depositEth{value: AMOUNT}(accountId);

        assertEq(engine.ethBalances(accountId), AMOUNT);
        assertEq(address(engine).balance, AMOUNT);
    }

    function test_depositEth_fuzz(
        uint256 fuzzedEthAmount,
        uint128 fuzzedAccountId
    ) public {
        vm.assume(fuzzedEthAmount < address(this).balance - 1 ether);

        engine.depositEth{value: fuzzedEthAmount}(fuzzedAccountId);

        assertEq(engine.ethBalances(fuzzedAccountId), fuzzedEthAmount);
        assertEq(address(engine).balance, fuzzedEthAmount);
    }

    function test_depositEth_event() public {
        vm.expectEmit(true, true, true, true);
        emit EthDeposit(accountId, AMOUNT);

        engine.depositEth{value: AMOUNT}(accountId);
    }
}

contract Withdraw is EthManagementTest {
    event EthWithdraw(uint128 indexed accountId, uint256 amount);

    function test_withdrawEth() public {
        engine.depositEth{value: AMOUNT}(accountId);

        assertEq(engine.ethBalances(accountId), AMOUNT);
        assertEq(address(engine).balance, AMOUNT);

        vm.prank(ACTOR);

        engine.withdrawEth(accountId, AMOUNT);

        assertEq(engine.ethBalances(accountId), 0);
        assertEq(address(engine).balance, 0);
    }

    function test_withdrawEth_fuzz(uint256 fuzzedEthAmount) public {
        vm.assume(fuzzedEthAmount <= AMOUNT);

        engine.depositEth{value: AMOUNT}(accountId);

        assertEq(engine.ethBalances(accountId), AMOUNT);
        assertEq(address(engine).balance, AMOUNT);

        vm.prank(ACTOR);

        engine.withdrawEth(accountId, fuzzedEthAmount);

        assertEq(engine.ethBalances(accountId), AMOUNT - fuzzedEthAmount);
        assertEq(address(engine).balance, AMOUNT - fuzzedEthAmount);
    }

    function test_withdrawEth_Unauthorized() public {
        engine.depositEth{value: AMOUNT}(accountId);

        vm.expectRevert(IEngine.Unauthorized.selector);

        vm.prank(BAD_ACTOR);

        engine.withdrawEth(accountId, AMOUNT);
    }

    function test_withdrawEth_InsufficientEthBalance() public {
        engine.depositEth{value: AMOUNT}(accountId);

        vm.expectRevert(IEngine.InsufficientEthBalance.selector);

        vm.prank(ACTOR);

        engine.withdrawEth(accountId, AMOUNT + 1);
    }

    function test_withdrawEth_EthTransferFailed() public {
        CantReceiveEth cantReceiveEth = new CantReceiveEth();

        engine.depositEth{value: AMOUNT}(accountId);

        mock_getAccountOwner(
            address(perpsMarketProxy), accountId, address(cantReceiveEth)
        );

        vm.prank(address(cantReceiveEth));

        vm.expectRevert(IEngine.EthTransferFailed.selector);

        engine.withdrawEth(accountId, AMOUNT);
    }

    function test_withdrawEth_event() public {
        engine.depositEth{value: AMOUNT}(accountId);

        vm.expectEmit(true, true, true, true);
        emit EthWithdraw(accountId, AMOUNT);

        vm.prank(ACTOR);

        engine.withdrawEth(accountId, AMOUNT);
    }
}

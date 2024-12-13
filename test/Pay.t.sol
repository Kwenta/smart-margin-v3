// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

import {Bootstrap} from "test/utils/Bootstrap.sol";
import {MaliciousReceiver} from "test/utils/MaliciousReceiver.sol";
import {Pay} from "src/utils/Pay.sol";
import {IWETH} from "src/interfaces/tokens/IWETH.sol";

contract PayTest is Bootstrap {
    Pay payLocal;
    Pay payFork;
    IWETH wethWrapped;

    function setUp() public {
        vm.rollFork(BASE_BLOCK_NUMBER);
        initializeBase();

        wethWrapped = IWETH(weth);
        payLocal = new Pay(weth);
        payFork = Pay(pay);
    }

    function test_unwrapAndPay_local() public {
        uint256 amount = 100;
        address to = address(1);
        uint256 balanceBefore = to.balance;

        // setup
        vm.deal(address(this), amount);
        wethWrapped.deposit{value: amount}();
        wethWrapped.approve(address(payLocal), amount);

        // unwrap
        payLocal.unwrapAndPay(amount, to);
        assertEq(to.balance, balanceBefore + amount);
    }

    function test_unwrapAndPay_local_fuzz(uint128 amount) public {
        address to = address(1);
        uint256 balanceBefore = to.balance;

        // setup
        vm.deal(address(this), amount);
        wethWrapped.deposit{value: amount}();
        wethWrapped.approve(address(payLocal), amount);

        // unwrap
        payLocal.unwrapAndPay(amount, to);
        assertEq(to.balance, balanceBefore + amount);
    }

    function test_unwrapAndPay_withMaliciousReceiver() public {
        uint256 amount = 100;
        MaliciousReceiver maliciousReceiver = new MaliciousReceiver();
        address to = address(maliciousReceiver);

        // setup
        vm.deal(address(this), amount);
        wethWrapped.deposit{value: amount}();
        wethWrapped.approve(address(payLocal), amount);

        // Expect the ETHTransferFailed error
        vm.expectRevert(Pay.ETHTransferFailed.selector);
        payLocal.unwrapAndPay(amount, to);
    }

    function test_unwrapAndPay_fork() public {
        uint256 amount = 100;
        address to = address(1);
        uint256 balanceBefore = to.balance;

        // setup
        vm.deal(address(this), amount);
        wethWrapped.deposit{value: amount}();
        wethWrapped.approve(address(payFork), amount);

        // unwrap
        payFork.unwrapAndPay(amount, to);
        assertEq(to.balance, balanceBefore + amount);
    }

    function test_unwrapAndPay_fork_fuzz(uint128 amount) public {
        address to = address(1);
        uint256 balanceBefore = to.balance;

        // setup
        vm.deal(address(this), amount);
        wethWrapped.deposit{value: amount}();
        wethWrapped.approve(address(payFork), amount);

        // unwrap
        payFork.unwrapAndPay(amount, to);
        assertEq(to.balance, balanceBefore + amount);
    }
}

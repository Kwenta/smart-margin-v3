// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

import {EIP7412} from "src/utils/EIP7412.sol";
import {
    EIP7412Mock,
    EIP7412MockRefund,
    EIP7412MockRevert
} from "test/utils/mocks/EIP7412Mock.sol";
import {Bootstrap} from "test/utils/Bootstrap.sol";

contract EIP7412Test is Bootstrap {
    EIP7412Mock eip7412Mock;
    EIP7412MockRefund eip7412MockRefund;
    EIP7412MockRevert eip7412MockRevert;

    function setUp() public {
        vm.rollFork(ARBITRUM_BLOCK_NUMBER);
        initializeArbitrum();

        eip7412Mock = new EIP7412Mock();
        eip7412MockRefund = new EIP7412MockRefund();
        eip7412MockRevert = new EIP7412MockRevert();
    }
}

contract FulfillOracleQuery is EIP7412Test {
    function test_fulfillOracleQuery(bytes calldata signedOffchainData)
        public
    {
        uint256 preBalance = address(this).balance;
        uint256 preBalanceeip7412Mock = address(eip7412Mock).balance;

        engine.fulfillOracleQuery{value: AMOUNT}(
            payable(address(eip7412Mock)), signedOffchainData
        );

        assertLt(address(this).balance, preBalance);
        assertEq(address(eip7412Mock).balance, preBalanceeip7412Mock + AMOUNT);
    }

    function test_fulfillOracleQuery_refund(bytes calldata signedOffchainData)
        public
    {
        uint256 preBalance = address(this).balance;

        // refunds are not supported
        vm.expectRevert("EIP7412MockRefund");

        engine.fulfillOracleQuery{value: AMOUNT}(
            payable(address(eip7412MockRefund)), signedOffchainData
        );

        assert(address(this).balance == preBalance);
    }

    function test_fulfillOracleQuery_revert(bytes calldata signedOffchainData)
        public
    {
        uint256 preBalance = address(this).balance;

        vm.expectRevert("EIP7412MockRevert");

        engine.fulfillOracleQuery{value: AMOUNT}(
            payable(address(eip7412MockRevert)), signedOffchainData
        );

        assert(address(this).balance == preBalance);
    }
}

contract MulticallFulfillOracleQuery is EIP7412Test {
    function test_fulfillOracleQuery_multicall(
        bytes calldata signedOffchainData
    ) public {
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(
            EIP7412.fulfillOracleQuery.selector,
            payable(address(eip7412Mock)),
            signedOffchainData
        );

        uint256 preBalance = address(this).balance;
        uint256 preBalanceeip7412Mock = address(eip7412Mock).balance;

        engine.multicall{value: AMOUNT}(data);

        assertLt(address(this).balance, preBalance);
        assertEq(address(eip7412Mock).balance, preBalanceeip7412Mock + AMOUNT);
    }

    function test_fulfillOracleQuery_multicall_double_spend(
        bytes calldata signedOffchainData
    ) public {
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(
            EIP7412.fulfillOracleQuery.selector,
            payable(address(eip7412Mock)),
            signedOffchainData
        );
        data[1] = abi.encodeWithSelector(
            EIP7412.fulfillOracleQuery.selector,
            payable(address(eip7412Mock)),
            signedOffchainData
        );

        // Reason: EvmError
        vm.expectRevert();

        engine.multicall{value: AMOUNT}(data);
    }
}

contract FulfillOracleQueryDepositETH is EIP7412Test {
    function test_fulfillOracleQuery_depositETH(
        bytes calldata signedOffchainData
    ) public {
        uint256 ORACLE_AMOUNT = 10;

        uint256 preBalance = address(this).balance;
        uint256 preBalanceeip7412Mock = address(eip7412Mock).balance;

        uint256 availableMargin =
            uint256(perpsMarketProxy.getAvailableMargin(accountId));
        assertEq(availableMargin, 0);

        engine.updatePricesAndDepositCollateralETH{value: SMALLEST_AMOUNT + ORACLE_AMOUNT}(
            payable(address(eip7412Mock)), signedOffchainData, accountId, 1, 10
        );

        assertLt(address(this).balance, preBalance);
        assertEq(address(eip7412Mock).balance, preBalanceeip7412Mock + ORACLE_AMOUNT);

        availableMargin =
            uint256(perpsMarketProxy.getAvailableMargin(accountId));
        uint256 expectedMargin = SMALLEST_AMOUNT * ETH_PRICE;
        assertWithinTolerance(expectedMargin, availableMargin, 2);
    }
}

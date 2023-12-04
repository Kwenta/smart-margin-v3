// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {EIP7412} from "src/utils/EIP7412.sol";
import {
    EIP7412Mock,
    EIP7412MockRefund,
    EIP7412MockRevert
} from "test/utils/mocks/EIP7412Mock.sol";
import {SynthetixMock} from "test/utils/mocks/SynthetixMock.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract EIP7412Test is Test, SynthetixMock {
    EIP7412Mock eip7412Mock;
    EIP7412MockRefund eip7412MockRefund;
    EIP7412MockRevert eip7412MockRevert;

    uint256 amount = 1 ether;

    function setUp() public {
        eip7412Mock = new EIP7412Mock();
        eip7412MockRefund = new EIP7412MockRefund();
        eip7412MockRevert = new EIP7412MockRevert();
    }

    function test_fulfillOracleQuery(bytes calldata signedOffchainData)
        public
    {
        EIP7412 eip7412 = new EIP7412();

        uint256 preBalance = address(this).balance;
        uint preBalanceeip7412Mock = address(eip7412Mock).balance;

        eip7412.fulfillOracleQuery{value: amount}(
            payable(address(eip7412Mock)), signedOffchainData
        );

        assertLt(address(this).balance, preBalance);
        assertEq(address(eip7412Mock).balance, preBalanceeip7412Mock + amount);
    }

    function test_fulfillOracleQuery_refund(bytes calldata signedOffchainData)
        public
    {
        EIP7412 eip7412 = new EIP7412();

        uint256 preBalance = address(this).balance;

        // refunds are not supported
        vm.expectRevert("EIP7412MockRefund");

        eip7412.fulfillOracleQuery{value: amount}(
            payable(address(eip7412MockRefund)), signedOffchainData
        );

        assert(address(this).balance == preBalance);
    }

    function test_fulfillOracleQuery_revert(bytes calldata signedOffchainData)
        public
    {
        EIP7412 eip7412 = new EIP7412();

        uint256 preBalance = address(this).balance;

        vm.expectRevert("EIP7412MockRevert");

        eip7412.fulfillOracleQuery{value: amount}(
            payable(address(eip7412MockRevert)), signedOffchainData
        );

        assert(address(this).balance == preBalance);
    }
}

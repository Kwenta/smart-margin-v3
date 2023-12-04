// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

contract EIP7412Mock {
    function fulfillOracleQuery(bytes calldata) external payable {}
}

contract EIP7412MockRefund {
    function fulfillOracleQuery(bytes calldata) external payable {
        (bool success,) = msg.sender.call{value: msg.value}("");
        require(success, "EIP7412MockRefund");
    }
}

contract EIP7412MockRevert {
    function fulfillOracleQuery(bytes calldata) external payable {
        revert("EIP7412MockRevert");
    }
}

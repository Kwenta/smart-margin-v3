// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

/// @title Contract(s) used to mock EIP-7412 Oracle functionality for testing purposes
/// @author JaredBorders (jaredborders@pm.me)
contract EIP7412Mock {
    event Success();

    function fulfillOracleQuery(bytes calldata) external payable {
        require(msg.value > 0, "EIP7412Mock");
        emit Success();
    }
}

contract EIP7412MockRefund {
    function fulfillOracleQuery(bytes calldata) external payable {
        assert(msg.value > 0);
        (bool success,) = msg.sender.call{value: msg.value}("");
        require(success, "EIP7412MockRefund");
    }
}

contract EIP7412MockRevert {
    function fulfillOracleQuery(bytes calldata) external payable {
        revert("EIP7412MockRevert");
    }
}

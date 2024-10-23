// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IERC20} from "../interfaces/IERC20.sol";

/// @title token flushing utility
/// @author @jaredborders
contract Flush {
    /// @custom:plumber
    address public PLUMBER;

    /// @notice thrown when caller is not the plumber
    error OnlyPlumber();

    ///@notice emitted when a new plumber is designated
    event PlumberDesignated(address plumber);

    constructor(address _plumber) {
        PLUMBER = _plumber;
    }

    /// @notice flush dust out of the contract
    /// @custom:plumber is the only authorized caller
    /// @param _token address of token to flush
    function flush(address _token) external {
        require(msg.sender == PLUMBER, OnlyPlumber());
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) token.transfer(msg.sender, balance);
    }

    /// @notice designate a new plumber
    /// @custom:plumber is the only authorized caller
    /// @dev zero address can be used to remove flush capability
    /// @param _newPlumber address of new plumber
    function designatePlumber(address _newPlumber) external {
        require(msg.sender == PLUMBER, OnlyPlumber());
        PLUMBER = _newPlumber;
        emit PlumberDesignated(_newPlumber);
    }
}

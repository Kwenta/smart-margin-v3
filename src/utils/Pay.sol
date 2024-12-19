// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

import {IWETH} from "src/interfaces/tokens/IWETH.sol";

/// @notice Pay contract for unwrapping WETH and sending it to a recipient
/// @author cmontecoding
contract Pay {
    /// @notice WETH contract
    IWETH public immutable WETH;

    /// @notice thrown when a call to transfer eth fails
    error ETHTransferFailed();

    constructor(address _weth) {
        WETH = IWETH(_weth);
    }

    /// @notice unwrap WETH and send it to a recipient
    /// @param amount amount of WETH to unwrap
    /// @param to recipient address
    function unwrapAndPay(uint256 amount, address to) public {
        WETH.transferFrom(msg.sender, address(this), amount);
        WETH.withdraw(amount);
        (bool success,) = to.call{value: amount}("");
        if (success != true) {
            revert ETHTransferFailed();
        }
    }

    receive() external payable {}
}

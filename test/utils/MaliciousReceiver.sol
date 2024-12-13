// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

/// @notice Helper contract that rejects ETH transfers
/// @author cmontecoding
contract MaliciousReceiver {
    receive() external payable {
        revert();
    }

    function onERC721Received(address, address, uint256, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return 0x150b7a02;
    }
}

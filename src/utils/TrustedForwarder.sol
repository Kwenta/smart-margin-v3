// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @dev Minimal Trusted Multicall Forwarder
/// @custom:derived from github.com/Synthetixio/trusted-multicall-forwarder
/// @author Jared Borders <jaredborders@pm.me>
contract TrustedForwarder {
    struct Call3Value {
        address target;
        bool requireSuccess;
        uint256 value;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    /// @dev The requestedValue doesn't match with the available msgValue
    error MismatchedValue(uint256 requestedValue, uint256 msgValue);

    /// @notice Aggregate calls with a msg value
    /// @notice Reverts if msg.value is less than the sum of the call values
    /// @param calls An array of Call3Value structs
    /// @return returnData An array of Result structs
    function aggregate3Value(
        Call3Value[] calldata calls
    ) public payable returns (Result[] memory returnData) {
        uint256 valAccumulator;
        Call3Value calldata calli;

        uint256 length = calls.length;
        returnData = new Result[](length);
        
        for (uint256 i = 0; i < length; ) {
            Result memory result = returnData[i];
            calli = calls[i];

            uint256 val = calli.value;

            unchecked {
                valAccumulator += val;
            }

            (result.success, result.returnData) = calli.target.call{value: val}(
                abi.encodePacked(calli.callData, msg.sender)
            );

            if (calli.requireSuccess && !result.success) {
                bytes memory revertData = result.returnData;
                uint256 len = revertData.length;
                assembly {
                    revert(add(revertData, 0x20), len)
                }
            }

            unchecked {
                ++i;
            }
        }

        // Finally, make sure the msg.value == SUM(call[0...i].value)
        if (msg.value != valAccumulator) {
            revert MismatchedValue(valAccumulator, msg.value);
        }
    }
}
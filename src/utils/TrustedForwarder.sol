// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC2771Context} from
    "lib/openzeppelin-contracts/contracts/metatx/ERC2771Context.sol";

/// @dev Minimal Trusted Multicall Forwarder
/// @custom:derived from github.com/Synthetixio/trusted-multicall-forwarder
/// @author Jared Borders <jaredborders@pm.me>
contract TrustedForwarder {
    struct Call {
        /// @notice The address called
        address target;
        /// @notice the allocated value for the call defined by this struct
        uint256 value;
        /// @notice the call data for the call defined by this struct
        bytes callData;
    }

    /// @dev thrown when requestedValue doesn't match with the available msgValue
    error MismatchedValue(uint256 requestedValue, uint256 msgValue);

    /// @dev thrown when the target contract does not trust this forwarder
    error TargetNotTrusted(address target);

    /// @notice Aggregate calls with a msg value
    /// @notice Reverts if msg.value is less than the sum of the call values
    /// @param calls An array of Call structs
    /// @return returnData An array of results from the calls
    function aggregate(Call[] calldata calls)
        public
        payable
        returns (bytes[] memory returnData)
    {
        uint256 valAccumulator;
        Call calldata calli;

        uint256 length = calls.length;
        returnData = new bytes[](length);

        for (uint256 i = 0; i < length;) {
            // define the call object
            calli = calls[i];

            /// @dev early exit;
            /// ensure the target trusts this forwarder else revert the whole tx
            if (!_isTrustedByTarget(calli.target)) {
                revert TargetNotTrusted(calli.target);
            }

            // define the allocated value for this call
            uint256 val = calli.value;

            // add the allocated value to the value accumulator
            // so we can check the msg.value at the end
            // to ensure it matches the sum of the call values
            valAccumulator += val;

            // make the call and record the result data and whether it was successful
            (bool success, bytes memory data) = calli.target.call{value: val}(
                abi.encodePacked(calli.callData, msg.sender)
            );

            // *ALWAYS* revert if the call was not successful
            /// @dev prevents ETH from being locked in the contract if call
            /// with non-zero value reverts
            if (!success) {
                bytes memory revertData = data;
                uint256 len = data.length;
                assembly {
                    revert(add(revertData, 0x20), len)
                }
            }

            returnData[i] = data;

            unchecked {
                ++i;
            }
        }

        // Post iteration, make sure the msg.value == SUM(call[0...i].value)
        if (msg.value != valAccumulator) {
            revert MismatchedValue(valAccumulator, msg.value);
        }
    }

    /// @dev Returns whether the target trusts this forwarder.
    /// This function performs a static call to the target contract calling the
    /// {ERC2771Context-isTrustedForwarder} function.
    function _isTrustedByTarget(address target) internal view returns (bool) {
        bytes memory encodedParams =
            abi.encodeCall(ERC2771Context.isTrustedForwarder, (address(this)));

        bool success;
        uint256 returnSize;
        uint256 returnValue;
        /// @solidity memory-safe-assembly
        assembly {
            // Perform the staticcal and save the result in the scratch space.
            // | Location  | Content  | Content (Hex)                                                      |
            // |-----------|----------|--------------------------------------------------------------------|
            // |           |          |                                                           result ↓ |
            // | 0x00:0x1F | selector | 0x0000000000000000000000000000000000000000000000000000000000000001 |
            success :=
                staticcall(
                    gas(),
                    target,
                    add(encodedParams, 0x20),
                    mload(encodedParams),
                    0,
                    0x20
                )
            returnSize := returndatasize()
            returnValue := mload(0)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

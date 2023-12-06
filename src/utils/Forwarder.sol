// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

/// @title Kwenta Smart Margin v3: Standalone Forwarder Contract
/// @author JaredBorders (jaredborders@pm.me)
contract Forwarder {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev There's no code at `target` (it is not a contract).
    error AddressEmptyCode(address target);

    /// @dev A call to an address target failed. The target may have reverted.
    error FailedInnerCall();

    /*//////////////////////////////////////////////////////////////
                               FORWARDING
    //////////////////////////////////////////////////////////////*/

    /// @notice forward a call to another contract via delegatecall
    /// @param target the target contract address being delegatecalled
    /// @param data the array of calldata to be executed on the target contract
    function forward(address target, bytes[] memory data)
        external
        payable
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);

        for (uint256 i = 0; i < data.length;) {
            results[i] = _functionDelegateCall(target, data[i]);

            unchecked {
                ++i;
            }
        }

        return results;
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
    /// but performing a delegate call.
    function _functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResultFromTarget(target, success, returndata);
    }

    /// @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
    /// was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
    /// unsuccessful call.
    function _verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /// @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
    function _revert(bytes memory returndata) internal pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

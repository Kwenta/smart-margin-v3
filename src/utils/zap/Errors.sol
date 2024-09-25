// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title zap errors
/// @author @jaredborders
contract Errors {

    /// @notice thrown when a wrap operation fails
    /// @param reason string for the failure
    error WrapFailed(string reason);

    /// @notice thrown when an unwrap operation fails
    /// @param reason string for the failure
    error UnwrapFailed(string reason);

    /// @notice thrown when a buy operation fails
    /// @param reason string for the failure
    error BuyFailed(string reason);

    /// @notice thrown when a sell operation fails
    /// @param reason string for the failure
    error SellFailed(string reason);

    /// @notice thrown when a swap operation fails
    /// @param reason string for the failure
    error SwapFailed(string reason);

    /// @notice thrown when operation is not permitted
    error NotPermitted();

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @title Kwenta Smart Margin v3: Math Library for int128 and int256
/// @author JaredBorders (jaredborders@pm.me)
library MathLib {
    error CannotTakeAbsOfMinInt128();
    error CannotTakeAbsOfMinInt256();

    /// @notice get absolute value of the input, returned as an unsigned number.
    /// @param x: signed number
    /// @return z uint128 absolute value of x
    function abs128(int128 x) internal pure returns (uint128 z) {
        if (x == type(int128).min) {
            revert CannotTakeAbsOfMinInt128();
        }

        /// @custom:todo can this be optimized similar to abs256?
        z = x < 0 ? uint128(-x) : uint128(x);
    }

    /// @notice get absolute value of the input, returned as an unsigned number.
    /// @param x: signed number
    /// @return z uint256 absolute value of x
    function abs256(int256 x) internal pure returns (uint256 z) {
        if (x == type(int256).min) {
            revert CannotTakeAbsOfMinInt256();
        }

        assembly {
            /// shr(255, x):
            /// shifts the number x to the right by 255 bits:
            /// IF the number is negative, the leftmost bit (bit 255) will be 1
            /// IF the number is positive,the leftmost bit (bit 255) will be 0

            /// sub(0, shr(255, x)):
            /// creates a mask of all 1s if x is negative
            /// creates a mask of all 0s if x is positive
            let mask := sub(0, shr(255, x))

            /// If x is negative, this effectively negates the number
            // if x is positive, it leaves the number unchanged, thereby computing the absolute value
            z := xor(mask, add(mask, x))
        }
    }

    /// @notice determines if input numbers have the same sign
    /// @dev asserts that both numbers are not zero
    /// @param x: signed number
    /// @param y: signed number
    /// @return true if same sign, false otherwise
    function isSameSign(int128 x, int128 y) internal pure returns (bool) {
        assert(x != 0 && y != 0);
        return (x ^ y) >= 0;
    }
}

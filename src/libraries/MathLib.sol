// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @title Kwenta Smart Margin v3: Math Library for int128 and int256
/// @author JaredBorders (jaredborders@pm.me)
library MathLib {
    error OverflowU128();

    /// @notice get absolute value of the input, returned as an unsigned number.
    /// @param x signed number
    /// @return z uint128 absolute value of x
    function abs128(int128 x) internal pure returns (uint128 z) {
        assembly {
            /// shr(127, x):
            /// shifts the number x to the right by 127 bits:
            /// IF the number is negative, the leftmost bit (bit 127) will be 1
            /// IF the number is positive, the leftmost bit (bit 127) will be 0
            let y := shr(127, x)

            /// sub(xor(x, y), y):
            /// IF x is negative, this effectively negates the number
            /// IF x is positive, it leaves the number unchanged, thereby computing the absolute value
            z := sub(xor(x, y), y)
        }
    }

    /// @notice get absolute value of the input, returned as an unsigned number.
    /// @param x signed number
    /// @return z uint256 absolute value of x
    function abs256(int256 x) internal pure returns (uint256 z) {
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
            /// if x is positive, it leaves the number unchanged, thereby computing the absolute value
            z := xor(mask, add(mask, x))
        }
    }

    /// @notice cast uint256 to uint128
    /// @dev asserts that input is not greater than uint128 max
    /// @param x unsigned 256-bit number
    /// @return downcasted uint128 from uint256
    function castU128(uint256 x) internal pure returns (uint128) {
        if (x > type(uint128).max) {
            revert OverflowU128();
        }
        return uint128(x);
    }

    /// @notice determines if input numbers have the same sign
    /// @dev asserts that both numbers are not zero
    /// @param x signed number
    /// @param y signed number
    /// @return true if same sign, false otherwise
    function isSameSign(int128 x, int128 y) internal pure returns (bool) {
        assert(x != 0 && y != 0);
        return (x ^ y) >= 0;
    }
}

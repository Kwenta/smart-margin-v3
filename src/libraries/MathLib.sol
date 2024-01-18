// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

/// @title Kwenta Smart Margin v3: Math Library for int128 and int256
/// @author JaredBorders (jaredborders@pm.me)
library MathLib {
    error Overflow();

    /// @notice get absolute value of the input, returned as an unsigned number.
    /// @param x signed 128-bit number
    /// @return z unsigned 128-bit absolute value of x
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
    /// @param x signed 256-bit number
    /// @return z unsigned 256-bit absolute value of x
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

    /// @notice determines if input numbers have the same sign
    /// @dev asserts that both numbers are not zero
    /// @param x signed 128-bit number
    /// @param y signed 128-bit number
    /// @return true if same sign, false otherwise
    function isSameSign(int128 x, int128 y) internal pure returns (bool) {
        assert(x != 0 && y != 0);
        return (x ^ y) >= 0;
    }

    /// @notice safely cast uint256 to int256
    /// @dev reverts if the input is greater than or equal to 2^255
    /// @param x unsigned 256-bit number
    /// @return z signed 256-bit number
    function toInt256(uint256 x) internal pure returns (int256) {
        if (x >= 1 << 255) {
            /// @solidity memory-safe-assembly
            assembly {
                // Store the function selector of `Overflow()`.
                mstore(0x00, 0x35278d12)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
        return int256(x);
    }
}

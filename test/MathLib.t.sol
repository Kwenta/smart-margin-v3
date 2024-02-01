// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {MathLib} from "src/libraries/MathLib.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract MathLibTest is Test {
    using MathLib for int128;
    using MathLib for int256;
    using MathLib for uint256;

    function test_abs128() public {
        int128 x = -1 ether;
        uint128 z = x.abs128();
        assertEq(z, 1 ether);

        x = type(int128).min;
        z = x.abs128();
        assertEq(z, 2 ** 127);

        x = type(int128).max;
        z = x.abs128();
        assertEq(z, (2 ** 127) - 1);

        int128 y = (2 ** 127) - 1;
        assertEq(x, y);
    }

    function test_fuzz_abs128(int128 x) public {
        uint128 z;

        if (x == type(int128).min) {
            z = x.abs128();
            assertEq(z, 2 ** 127);
        } else if (x == type(int128).max) {
            z = x.abs128();
            assertEq(z, (2 ** 127) - 1);
        } else {
            z = x.abs128();
            x = x < 0 ? -x : x;
            uint128 y = uint128(x);

            assertEq(z, y);
        }
    }

    function test_abs256() public {
        int256 x = -1 ether;
        uint256 z = x.abs256();
        assertEq(z, 1 ether);

        x = type(int256).min;
        z = x.abs256();
        assertEq(z, 2 ** 255);

        x = type(int256).max;
        z = x.abs256();
        assertEq(z, (2 ** 255) - 1);

        int256 y = (2 ** 255) - 1;
        assertEq(x, y);
    }

    function test_fuzz_abs256(int256 x) public {
        uint256 z;

        if (x == type(int256).min) {
            z = x.abs256();
            assertEq(z, 2 ** 255);
        } else if (x == type(int256).max) {
            z = x.abs256();
            assertEq(z, (2 ** 255) - 1);
        } else {
            z = x.abs256();
            x = x < 0 ? -x : x;
            uint256 y = uint256(x);
            assertEq(z, y);
        }
    }

    function test_isSameSign() public {
        int128 x = -1;
        int128 y = -1;
        assertTrue(x.isSameSign(y));

        x = 1;
        y = 1;
        assertTrue(x.isSameSign(y));

        x = 1;
        y = -1;
        assertFalse(x.isSameSign(y));

        x = -1;
        y = 1;
        assertFalse(x.isSameSign(y));
    }

    function test_toInt256() public {
        uint256 x = 1 ether;
        int256 z = x.toInt256();
        assertEq(z, 1 ether);

        x = type(uint256).min;
        z = x.toInt256();
        assertEq(z, 0);

        x = type(uint256).max;
        vm.expectRevert(MathLib.Overflow.selector);
        z = x.toInt256();
    }

    function test_toInt256_overflow() public {
        uint256 x = (2 ** 255) - 1;
        int256 z = x.toInt256();
        assertEq(z, (2 ** 255) - 1);

        x = 2 ** 255;
        vm.expectRevert(MathLib.Overflow.selector);
        z = x.toInt256();
    }

    function test_fuzz_toInt256(uint256 x) public {
        int256 z;

        if (x >= 2 ** 255) {
            vm.expectRevert(MathLib.Overflow.selector);
            z = x.toInt256();
        } else {
            z = x.toInt256();
            assertEq(z, int256(x));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {MathLib} from "src/libraries/MathLib.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract MathLibTest is Test {
    using MathLib for int128;
    using MathLib for int256;
    using MathLib for uint256;

    function test_abs128() public {
        int128 x = -1 ether;
        uint128 z = x.abs128();
        assertTrue(z == 1 ether);
    }

    function test_abs128_min() public {
        int128 x = type(int128).min;

        vm.expectRevert(
            abi.encodeWithSelector(MathLib.CannotTakeAbsOfMinInt128.selector)
        );

        x.abs128();
    }

    function test_abs256() public {
        int256 x = -1 ether;
        uint256 z = x.abs256();
        assertTrue(z == 1 ether);
    }

    function test_abs256_min() public {
        int256 x = type(int256).min;

        vm.expectRevert(
            abi.encodeWithSelector(MathLib.CannotTakeAbsOfMinInt256.selector)
        );

        x.abs256();
    }

    function test_castU128() public {
        uint256 x = 1 ether;
        uint128 z = x.castU128();
        assertTrue(z == 1 ether);
    }

    function test_castU128_overflow() public {
        uint256 x = type(uint128).max;
        x++;

        vm.expectRevert(abi.encodeWithSelector(MathLib.OverflowU128.selector));

        x.castU128();
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
}

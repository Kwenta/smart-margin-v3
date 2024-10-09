// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

contract TestHelpers {
    function assertWithinTolerance(uint256 expected, uint256 actual, uint256 tolerancePercent) internal {
        uint256 tolerance = (expected * tolerancePercent) / 100;
        assert(actual >= expected - tolerance && actual <= expected + tolerance);
    }
}
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

contract PricesMock {
    function getPricesInWei() external pure returns (uint256) {
        return 10000000000000000;
    }
}
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

contract Events {
    event AccountCreated(uint256 accountId);
    event MarginDeposited(
        uint256 accountId, address marginType, uint256 amount
    );
    event MarginWithdrawn(
        uint256 accountId, address marginType, uint256 amount
    );
    event CollateralDeposited(
        uint256 accountId, address collateralType, uint256 amount
    );
    event CollateralWithdrawn(
        uint256 accountId, address collateralType, uint256 amount
    );
}

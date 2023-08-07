// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Multicallable} from "src/utils/Multicallable.sol";

contract MarginEngine is Multicallable {
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

    function createAccount(uint256 _desiredAccountId) external {
        emit AccountCreated(_desiredAccountId);
    }

    function depositMargin(
        uint256 accountId,
        address marginType,
        uint256 amount
    ) external {
        emit MarginDeposited(accountId, marginType, amount);
    }

    function withdrawMargin(
        uint256 accountId,
        address marginType,
        uint256 amount
    ) external {
        emit MarginWithdrawn(accountId, marginType, amount);
    }

    function depositCollateral(
        uint256 accountId,
        address marginType,
        uint256 amount
    ) external {
        emit CollateralDeposited(accountId, marginType, amount);
    }

    function withdrawCollateral(
        uint256 accountId,
        address marginType,
        uint256 amount
    ) external {
        emit CollateralWithdrawn(accountId, marginType, amount);
    }
}

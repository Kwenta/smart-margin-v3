// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

/// @title Consolidated functions from Synthetix v3 Perps Market contracts
/// @dev Used for testing purposes but not used in the src/* contracts
/// @author JaredBorders (jaredborders@pm.me)
interface IPerpsMarketProxy {
    function createAccount() external returns (uint128 accountId);

    function getAccountOwner(uint128 accountId)
        external
        view
        returns (address owner);

    function grantPermission(
        uint128 accountId,
        bytes32 permission,
        address user
    ) external;

    function hasPermission(uint128 accountId, bytes32 permission, address user)
        external
        view
        returns (bool hasPermission);

    function isAuthorized(uint128 accountId, bytes32 permission, address target)
        external
        view
        returns (bool isAuthorized);

    struct Data {
        uint256 settlementTime;
        OrderCommitmentRequest request;
    }

    struct OrderCommitmentRequest {
        uint128 marketId;
        uint128 accountId;
        int128 sizeDelta;
        uint128 settlementStrategyId;
        uint256 acceptablePrice;
        bytes32 trackingCode;
        address referrer;
    }

    function commitOrder(OrderCommitmentRequest memory commitment)
        external
        returns (Data memory retOrder, uint256 fees);

    function requiredMarginForOrder(
        uint128 accountId,
        uint128 marketId,
        int128 sizeDelta
    ) external view returns (uint256 requiredMargin);

    function computeOrderFees(uint128 marketId, int128 sizeDelta)
        external
        view
        returns (uint256 orderFees, uint256 fillPrice);

    function modifyCollateral(
        uint128 accountId,
        uint128 synthMarketId,
        int256 amountDelta
    ) external;

    function getCollateralAmount(uint128 accountId, uint128 synthMarketId)
        external
        view
        returns (uint256);

    function totalCollateralValue(uint128 accountId)
        external
        view
        returns (uint256);

    function getOpenPosition(uint128 accountId, uint128 marketId)
        external
        view
        returns (int256 totalPnl, int256 accruedFunding, int128 positionSize);

    function getAvailableMargin(uint128 accountId)
        external
        view
        returns (int256 availableMargin);

    function getMaxMarketSize(uint128 marketId)
        external
        view
        returns (uint256 maxMarketSize);
}

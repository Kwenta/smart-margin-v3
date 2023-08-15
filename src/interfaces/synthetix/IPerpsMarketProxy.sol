// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

interface IPerpsMarketProxy {
    /*//////////////////////////////////////////////////////////////
                             ACCOUNT MODULE
    //////////////////////////////////////////////////////////////*/

    /// @notice Mints an account token with an available id to `msg.sender`.
    /// Emits a {AccountCreated} event.
    function createAccount() external returns (uint128 accountId);

    /// @notice Returns the address that owns a given account, as recorded by the system.
    /// @param accountId The account id whose owner is being retrieved.
    /// @return owner The owner of the given account id.
    function getAccountOwner(uint128 accountId)
        external
        view
        returns (address owner);

    /// @notice Grants `permission` to `user` for account `accountId`.
    /// @param accountId The id of the account that granted the permission.
    /// @param permission The bytes32 identifier of the permission.
    /// @param user The target address that received the permission.
    /// @dev `msg.sender` must own the account token with ID `accountId` or have the "admin" permission.
    /// @dev Emits a {PermissionGranted} event.
    function grantPermission(
        uint128 accountId,
        bytes32 permission,
        address user
    ) external;

    /// @notice Revokes `permission` from `user` for account `accountId`.
    /// @param accountId The id of the account that revoked the permission.
    /// @param permission The bytes32 identifier of the permission.
    /// @param user The target address that no longer has the permission.
    /// @dev `msg.sender` must own the account token with ID `accountId` or have the "admin" permission.
    /// @dev Emits a {PermissionRevoked} event.
    function revokePermission(
        uint128 accountId,
        bytes32 permission,
        address user
    ) external;

    /// @notice Returns `true` if `user` has been granted `permission` for account `accountId`.
    /// @param accountId The id of the account whose permission is being queried.
    /// @param permission The bytes32 identifier of the permission.
    /// @param user The target address whose permission is being queried.
    /// @return hasPermission A boolean with the response of the query.
    function hasPermission(uint128 accountId, bytes32 permission, address user)
        external
        view
        returns (bool hasPermission);

    /*//////////////////////////////////////////////////////////////
                           ASYNC ORDER MODULE
    //////////////////////////////////////////////////////////////*/

    struct Data {
        /// @dev Time at which the Settlement time is open.
        uint256 settlementTime;
        /// @dev Order request details.
        OrderCommitmentRequest request;
    }

    struct OrderCommitmentRequest {
        /// @dev Order market id.
        uint128 marketId;
        /// @dev Order account id.
        uint128 accountId;
        /// @dev Order size delta (of asset units expressed in decimal 18 digits). It can be positive or negative.
        int128 sizeDelta;
        /// @dev Settlement strategy used for the order.
        uint128 settlementStrategyId;
        /// @dev Acceptable price set at submission.
        uint256 acceptablePrice;
        /// @dev An optional code provided by frontends to assist with tracking the source of volume and fees.
        bytes32 trackingCode;
        /// @dev Referrer address to send the referrer fees to.
        address referrer;
    }

    /// @notice Commit an async order via this function
    /// @param commitment Order commitment data (see OrderCommitmentRequest struct).
    /// @return retOrder order details (see AsyncOrder.Data struct).
    /// @return fees order fees (protocol + settler)
    function commitOrder(OrderCommitmentRequest memory commitment)
        external
        returns (Data memory retOrder, uint256 fees);

    /*//////////////////////////////////////////////////////////////
                          PERPS ACCOUNT MODULE
    //////////////////////////////////////////////////////////////*/

    /// @notice Gets thrown when the amount delta is zero.
    error InvalidAmountDelta(int256 amountDelta);

    /// @notice Modify the collateral delegated to the account.
    /// @param accountId Id of the account.
    /// @param synthMarketId Id of the synth market used as collateral. Synth market id, 0 for snxUSD.
    /// @param amountDelta requested change in amount of collateral delegated to the account.
    function modifyCollateral(
        uint128 accountId,
        uint128 synthMarketId,
        int256 amountDelta
    ) external;

    /// @notice Gets the account's collateral value for a specific collateral.
    /// @param accountId Id of the account.
    /// @param synthMarketId Id of the synth market used as collateral. Synth market id, 0 for snxUSD.
    /// @return collateralValue collateral value of the account.
    function getCollateralAmount(uint128 accountId, uint128 synthMarketId)
        external
        view
        returns (uint256);

    /// @notice Gets the account's total collateral value.
    /// @param accountId Id of the account.
    /// @return collateralValue total collateral value of the account. USD denominated.
    function totalCollateralValue(uint128 accountId)
        external
        view
        returns (uint256);

    /// @notice Gets the account's total open interest value.
    /// @param accountId Id of the account.
    /// @return openInterestValue total open interest value of the account.
    function totalAccountOpenInterest(uint128 accountId)
        external
        view
        returns (uint256);

    /// @notice Gets the details of an open position.
    /// @param accountId Id of the account.
    /// @param marketId Id of the position market.
    /// @return totalPnl pnl of the entire position including funding.
    /// @return accruedFunding accrued funding of the position.
    /// @return positionSize size of the position.
    function getOpenPosition(uint128 accountId, uint128 marketId)
        external
        view
        returns (int256 totalPnl, int256 accruedFunding, int128 positionSize);

    /// @notice Gets the available margin of an account. It can be negative due to pnl.
    /// @param accountId Id of the account.
    /// @return availableMargin available margin of the position.
    function getAvailableMargin(uint128 accountId)
        external
        view
        returns (int256 availableMargin);

    /// @notice Gets the exact withdrawable amount a trader has available from this account while holding the account's current positions.
    /// @param accountId Id of the account.
    /// @return withdrawableMargin available margin to withdraw.
    function getWithdrawableMargin(uint128 accountId)
        external
        view
        returns (int256 withdrawableMargin);

    /// @notice Gets the initial/maintenance margins across all positions that an account has open.
    /// @param accountId Id of the account.
    /// @return requiredInitialMargin initial margin req (used when withdrawing collateral).
    /// @return requiredMaintenanceMargin maintenance margin req (used to determine liquidation threshold).
    function getRequiredMargins(uint128 accountId)
        external
        view
        returns (
            uint256 requiredInitialMargin,
            uint256 requiredMaintenanceMargin
        );

    /*//////////////////////////////////////////////////////////////
                          PERPS MARKET MODULE
    //////////////////////////////////////////////////////////////*/

    struct MarketSummary {
        int256 skew;
        uint256 size;
        uint256 maxOpenInterest;
        int256 currentFundingRate;
        int256 currentFundingVelocity;
        uint256 indexPrice;
    }

    function metadata(uint128 marketId)
        external
        view
        returns (string memory name, string memory symbol);

    function skew(uint128 marketId) external view returns (int256);

    function size(uint128 marketId) external view returns (uint256);

    function maxOpenInterest(uint128 marketId)
        external
        view
        returns (uint256);

    function currentFundingRate(uint128 marketId)
        external
        view
        returns (int256);

    function currentFundingVelocity(uint128 marketId)
        external
        view
        returns (int256);

    function indexPrice(uint128 marketId) external view returns (uint256);

    function fillPrice(uint128 marketId, int128 orderSize, uint256 price)
        external
        returns (uint256);

    /// @dev Given a marketId return a market's summary details in one call.
    function getMarketSummary(uint128 marketId)
        external
        view
        returns (MarketSummary memory summary);
}

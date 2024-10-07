// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

/// @title Consolidated Perpetuals Market Proxy Interface
/// @notice Responsible for interacting with Synthetix v3 perps markets
/// @author Synthetix
interface IPerpsMarketProxy {
    /*//////////////////////////////////////////////////////////////
                             ACCOUNT MODULE
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the address that owns a given account, as recorded by the system.
    /// @param accountId The account id whose owner is being retrieved.
    /// @return owner The owner of the given account id.
    function getAccountOwner(uint128 accountId)
        external
        view
        returns (address owner);

    /// @notice Returns `true` if `user` has been granted `permission` for account `accountId`.
    /// @param accountId The id of the account whose permission is being queried.
    /// @param permission The bytes32 identifier of the permission.
    /// @param user The target address whose permission is being queried.
    /// @return hasPermission A boolean with the response of the query.
    function hasPermission(uint128 accountId, bytes32 permission, address user)
        external
        view
        returns (bool hasPermission);

    function grantPermission(
        uint128 accountId,
        bytes32 permission,
        address user
    ) external;

    function renouncePermission(uint128 accountId, bytes32 permission)
        external;

    /// @notice Returns `true` if `target` is authorized to `permission` for account `accountId`.
    /// @param accountId The id of the account whose permission is being queried.
    /// @param permission The bytes32 identifier of the permission.
    /// @param target The target address whose permission is being queried.
    /// @return isAuthorized A boolean with the response of the query.
    function isAuthorized(uint128 accountId, bytes32 permission, address target)
        external
        view
        returns (bool isAuthorized);

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

    /// @notice Simulates what the order fee would be for the given market with the specified size.
    /// @dev Note that this does not include the settlement reward fee, which is based on the strategy type used
    /// @param marketId id of the market.
    /// @param sizeDelta size of position.
    /// @return orderFees incurred fees.
    /// @return fillPrice price at which the order would be filled.
    function computeOrderFees(uint128 marketId, int128 sizeDelta)
        external
        view
        returns (uint256 orderFees, uint256 fillPrice);

    /*//////////////////////////////////////////////////////////////
                          PERPS ACCOUNT MODULE
    //////////////////////////////////////////////////////////////*/

    /// @notice Modify the collateral delegated to the account.
    /// @param accountId Id of the account.
    /// @param synthMarketId Id of the synth market used as collateral. Synth market id, 0 for snxUSD.
    /// @param amountDelta requested change in amount of collateral delegated to the account.
    function modifyCollateral(
        uint128 accountId,
        uint128 synthMarketId,
        int256 amountDelta
    ) external;

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

    /*//////////////////////////////////////////////////////////////
                          PERPS MARKET MODULE
    //////////////////////////////////////////////////////////////*/

    /// @notice Gets the max size of an specific market.
    /// @param marketId id of the market.
    /// @return maxMarketSize the max market size in market asset units.
    function getMaxMarketSize(uint128 marketId)
        external
        view
        returns (uint256 maxMarketSize);

    /*//////////////////////////////////////////////////////////////
                                DEBT
    //////////////////////////////////////////////////////////////*/

    function payDebt(uint128 accountId, uint256 amount) external;
}

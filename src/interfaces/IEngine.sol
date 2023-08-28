// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";

/// @title Kwenta Smart Margin v3: Engine Interface
/// @author JaredBorders (jaredborders@pm.me)
interface IEngine {
    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/

    /// @notice stats for an account
    struct AccountStats {
        // totalFees the total fees paid by the account
        uint256 totalFees;
        // totalVolume the total volume traded by the account
        uint128 totalVolume;
        // totalTrades the total number of trades made by the account
        uint128 totalTrades;
    }

    /// @notice order details used to create an order on a perps market within a conditional order
    struct OrderDetails {
        // order market id
        uint128 marketId;
        // order account id
        uint128 accountId;
        // order size delta (of asset units expressed in decimal 18 digits). It can be positive or negative
        int128 sizeDelta;
        // settlement strategy used for the order
        uint128 settlementStrategyId;
        // acceptable price set at submission
        uint256 acceptablePrice;
        // bool to indicate if the order is reduce only; i.e. it can only reduce the position size
        bool isReduceOnly;
    }

    /// @notice conditional order
    struct ConditionalOrder {
        // order details
        OrderDetails orderDetails;
        // address of the signer of the order
        address signer;
        // an incrementing value indexed per order
        uint128 nonce;
        // option to require all extra conditions to be verified on-chain
        bool requireVerified;
        // address that can execute the order if requireVerified is false
        address trustedExecutor;
        // array of extra conditions to be met
        bytes[] conditions;
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice thrown when msg.sender is not authorized to interact with an account
    error Unauthorized();

    /// @notice thrown when an order cannot be executed
    error CannotExecuteOrder();

    /*//////////////////////////////////////////////////////////////
                             CREATE ACCOUNT
    //////////////////////////////////////////////////////////////*/

    /// @notice create an account
    /// @dev the msg sender will be the owner of the account
    /// @dev the Engine will have admin rights over the account
    /// @return accountId the id of the account created
    function createAccount() external returns (uint128 accountId);

    /*//////////////////////////////////////////////////////////////
                                 STATS
    //////////////////////////////////////////////////////////////*/

    /// @notice get the stats for an account
    /// @param _accountId the account to get stats for
    /// @return stats the stats for the account
    function getAccountStats(uint128 _accountId)
        external
        view
        returns (AccountStats memory);

    /*//////////////////////////////////////////////////////////////
                             AUTHENTICATION
    //////////////////////////////////////////////////////////////*/

    /// @notice check if the msg.sender is the owner of the account
    /// identified by the accountId
    /// @param _accountId the id of the account to check
    /// @param _caller the address to check
    /// @return true if the msg.sender is the owner of the account
    function isAccountOwner(uint128 _accountId, address _caller)
        external
        view
        returns (bool);

    /// @notice check if the msg.sender is a delegate of the account
    /// identified by the accountId
    /// @param _accountId the id of the account to check
    /// @param _caller the address to check
    /// @return true if the msg.sender is a delegate of the account
    function isAccountDelegate(uint128 _accountId, address _caller)
        external
        view
        returns (bool);

    /*//////////////////////////////////////////////////////////////
                         COLLATERAL MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice modify the collateral of an account identified by the accountId
    /// @param _accountId the account to modify
    /// @param _synthMarketId the id of the synth being used as collateral
    /// @param _amount the amount of collateral to add or remove (negative to remove)
    function modifyCollateral(
        uint128 _accountId,
        uint128 _synthMarketId,
        int256 _amount
    ) external;

    /*//////////////////////////////////////////////////////////////
                         ASYNC ORDER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice commit an order for an account identified by the
    /// accountId to be executed asynchronously
    /// @param _perpsMarketId the id of the perps market to trade
    /// @param _accountId the id of the account to trade with
    /// @param _sizeDelta the amount of the order to trade (short if negative, long if positive)
    /// @param _settlementStrategyId the id of the settlement strategy to use
    /// @param _acceptablePrice acceptable price set at submission. Compared against the fill price
    /// @return retOrder the order committed
    /// @return fees the fees paid for the order
    function commitOrder(
        uint128 _perpsMarketId,
        uint128 _accountId,
        int128 _sizeDelta,
        uint128 _settlementStrategyId,
        uint256 _acceptablePrice
    ) external returns (IPerpsMarketProxy.Data memory retOrder, uint256 fees);

    /*//////////////////////////////////////////////////////////////
                      CONDITIONAL ORDER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice execute a conditional order
    /// @param _co the conditional order
    /// @param _signature the signature of the conditional order
    /// @return retOrder the order committed
    /// @return fees the fees paid for the order
    function execute(ConditionalOrder calldata _co, bytes calldata _signature)
        external
        returns (IPerpsMarketProxy.Data memory retOrder, uint256 fees);

    /// @notice checks if the order can be executed based on defined conditions
    /// @dev this function does NOT check if the order can be executed based on the account's balance
    /// (i.e. does not check if enough USD is available to pay for the order fee nor does it check
    /// if enough collateral is available to cover the order)
    /// @param _co the conditional order
    /// @param _signature the signature of the conditional order
    /// @return true if the order can be executed based on defined conditions, false otherwise
    function canExecute(
        ConditionalOrder calldata _co,
        bytes calldata _signature
    ) external returns (bool);

    /// @notice verify the conditional order signer is the owner or delegate of the account
    /// @param _co the conditional order
    /// @return true if the signer is the owner or delegate of the account
    function verifySigner(ConditionalOrder calldata _co)
        external
        view
        returns (bool);

    /// @notice verify the signature of the conditional order
    /// @param _co the conditional order
    /// @param _signature the signature of the conditional order
    /// @return true if the signature is valid
    function verifySignature(
        ConditionalOrder calldata _co,
        bytes calldata _signature
    ) external view returns (bool);

    /// @notice verify array of conditions defined in the conditional order
    /// @param _co the conditional order
    /// @return true if all conditions are met
    function verifyConditions(ConditionalOrder calldata _co)
        external
        returns (bool);

    /*//////////////////////////////////////////////////////////////
                               CONDITIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice determine if current timestamp is after the given timestamp
    /// @param _timestamp the timestamp to compare against
    /// @return true if current timestamp is after the given timestamp, false otherwise
    function isTimestampAfter(uint256 _timestamp)
        external
        view
        returns (bool);

    /// @notice determine if current timestamp is before the given timestamp
    /// @param _timestamp the timestamp to compare against
    /// @return true if current timestamp is before the given timestamp, false otherwise
    function isTimestampBefore(uint256 _timestamp)
        external
        view
        returns (bool);

    /// @notice determine if the current price of an asset is above a given price
    /// @dev assets price is determined by the pyth oracle
    /// @param _assetId id of an asset to check the price of
    /// @param _price the price to compare against
    /// @return true if the current price of the asset is above the given price, false otherwise
    function isPriceAbove(bytes32 _assetId, int64 _price)
        external
        view
        returns (bool);

    /// @notice determine if the current price of an asset is below a given price
    /// @dev assets price is determined by the pyth oracle
    /// @param _assetId id of an asset to check the price of
    /// @param _price the price to compare against
    /// @return true if the current price of the asset is below the given price, false otherwise
    function isPriceBelow(bytes32 _assetId, int64 _price)
        external
        view
        returns (bool);

    /// @notice can market accept non close-only orders (i.e. is the market open)
    /// @dev if maxMarketSize to 0, the market will be in a close-only state
    /// @param _marketId the id of the market to check
    /// @return true if the market is open, false otherwise
    function isMarketOpen(uint128 _marketId) external view returns (bool);
}

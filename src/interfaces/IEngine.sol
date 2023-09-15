// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";

/// @title Kwenta Smart Margin v3: Engine Interface
/// @author JaredBorders (jaredborders@pm.me)
interface IEngine {
    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/

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
        // tracking code to identify the integrator
        bytes32 trackingCode;
        // address of the referrer
        address referrer;
    }

    /// @notice conditional order
    struct ConditionalOrder {
        // order details
        OrderDetails orderDetails;
        // address of the signer of the order
        address signer;
        // an incrementing value indexed per order
        uint256 nonce;
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

    /// @notice thrown when number of conditions exceeds max allowed
    /// @dev used to prevent griefing attacks
    error MaxConditionSizeExceeded();

    /// @notice thrown when address is zero
    error ZeroAddress();

    /// @notice thrown when attempting to re-use a nonce
    error InvalidNonce();

    /// @notice thrown when attempting to verify a condition identified by an invalid selector
    error InvalidConditionSelector(bytes4 selector);

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted when the account owner or delegate successfully invalidates an unordered nonce
    event UnorderedNonceInvalidation(
        uint128 indexed accountId, uint256 word, uint256 mask
    );

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
    /// @dev a delegate is an address that has been given
    /// PERPS_COMMIT_ASYNC_ORDER_PERMISSION permission
    /// @param _accountId the id of the account to check
    /// @param _caller the address to check
    /// @return true if the msg.sender is a delegate of the account
    function isAccountDelegate(uint128 _accountId, address _caller)
        external
        view
        returns (bool);

    /*//////////////////////////////////////////////////////////////
                            NONCE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice invalidates the bits specified in mask for the bitmap at the word position
    /// @dev the wordPos is maxed at type(uint248).max
    /// @param _accountId the id of the account to invalidate the nonces for
    /// @param _wordPos a number to index the nonceBitmap at
    /// @param _mask a bitmap masked against msg.sender's current bitmap at the word position
    function invalidateUnorderedNonces(
        uint128 _accountId,
        uint256 _wordPos,
        uint256 _mask
    ) external;

    /// @notice check if the given nonce has been used
    /// @param _accountId the id of the account to check
    /// @param _nonce the nonce to check
    /// @return true if the nonce has been used, false otherwise
    function hasUnorderedNonceBeenUsed(uint128 _accountId, uint256 _nonce)
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
    /// @param _trackingCode tracking code to identify the integrator
    /// @param _referrer the address of the referrer
    /// @return retOrder the order committed
    /// @return fees the fees paid for the order
    function commitOrder(
        uint128 _perpsMarketId,
        uint128 _accountId,
        int128 _sizeDelta,
        uint128 _settlementStrategyId,
        uint256 _acceptablePrice,
        bytes32 _trackingCode,
        address _referrer
    ) external returns (IPerpsMarketProxy.Data memory retOrder, uint256 fees);

    /*//////////////////////////////////////////////////////////////
                      CONDITIONAL ORDER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// In order for a conditional order to be committed and then executed there are a number of requirements that need to be met:
    ///
    /// (1)     The account must have sufficient snxUSD collateral to handle the order
    /// (2)     The account must not have another order committed
    /// (3)     The order’s set `acceptablePrice` needs to be met both on committing the order and when it gets executed
    ///         (users should choose a value for this that is likely to execute based on the conditions set)
    /// (4)     The order can only be executed within Synthetix’s set settlement window
    /// (5)     There must be a keeper that executes a conditional order
    ///
    /// @notice There is no guarantee a conditional order will be executed

    /// @notice execute a conditional order
    /// @param _co the conditional order
    /// @param _signature the signature of the conditional order
    /// @return retOrder the order committed
    /// @return fees the fees paid for the order to Synthetix
    /// @return conditionalOrderFee the fee paid to executor for the conditional order
    function execute(ConditionalOrder calldata _co, bytes calldata _signature)
        external
        returns (
            IPerpsMarketProxy.Data memory retOrder,
            uint256 fees,
            uint256 conditionalOrderFee
        );

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
    ) external view returns (bool);

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
    /// @dev
    ///     1. all conditions are defined by the conditional order creator
    ///     2. conditions are encoded function selectors and parameters
    ///     3. each function defined in the condition contract must return a truthy value
    ///     4. internally, staticcall is used to protect against malicious conditions
    /// @param _co the conditional order
    /// @return true if all conditions are met
    function verifyConditions(ConditionalOrder calldata _co)
        external
        view
        returns (bool);

    /*//////////////////////////////////////////////////////////////
                               CONDITIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice determine if current timestamp is after the given timestamp
    /// @param _timestamp the timestamp to compare against
    /// @return true if current timestamp is after the given `_timestamp`, false otherwise
    function isTimestampAfter(uint256 _timestamp)
        external
        view
        returns (bool);

    /// @notice determine if current timestamp is before the given timestamp
    /// @param _timestamp the timestamp to compare against
    /// @return true if current timestamp is before the given `_timestamp`, false otherwise
    function isTimestampBefore(uint256 _timestamp)
        external
        view
        returns (bool);

    /// @notice determine if the current price of an asset is above a given price
    /// @dev assets price is determined by the pyth oracle
    /// @param _assetId id of an asset to check the price of
    /// @param _price the price to compare against
    /// @param _confidenceInterval roughly corresponds to the standard error of a normal distribution
    ///
    /// example:
    /// given:
    /// PythStructs.Price.expo (expo) = -5
    /// confidenceInterval (conf) = 1500
    /// PythStructs.Price.price (price) = 12276250
    ///
    /// conf * 10^(expo) = 1500 * 10^(-5) = $0.015
    /// price * 10^(-5) = 12276250 * 10^(-5) = $122.7625
    ///
    /// thus, the price of the asset is $122.7625 +/- $0.015
    ///
    /// @return true if the current price of the asset is above the given `_price`, false otherwise
    function isPriceAbove(
        bytes32 _assetId,
        int64 _price,
        uint64 _confidenceInterval
    ) external view returns (bool);

    /// @notice determine if the current price of an asset is below a given price
    /// @dev assets price is determined by the pyth oracle
    /// @param _assetId id of an asset to check the price of
    /// @param _price the price to compare against
    /// @param _confidenceInterval roughly corresponds to the standard error of a normal distribution
    ///
    /// example:
    /// given:
    /// PythStructs.Price.expo (expo) = -5
    /// confidenceInterval (conf) = 1500
    /// PythStructs.Price.price (price) = 12276250
    ///
    /// conf * 10^(expo) = 1500 * 10^(-5) = $0.015
    /// price * 10^(-5) = 12276250 * 10^(-5) = $122.7625
    ///
    /// thus, the price of the asset is $122.7625 +/- $0.015
    ///
    /// @return true if the current price of the asset is below the given `_price`, false otherwise
    function isPriceBelow(
        bytes32 _assetId,
        int64 _price,
        uint64 _confidenceInterval
    ) external view returns (bool);

    /// @notice can market accept non close-only orders (i.e. is the market open)
    /// @dev if maxMarketSize to 0, the market will be in a close-only state
    /// @param _marketId the id of the market to check
    /// @return true if the market is open, false otherwise
    function isMarketOpen(uint128 _marketId) external view returns (bool);

    /// @notice determine if the account's (identified by the given accountId)
    /// position size in the given market is above a given size
    /// @param _accountId the id of the account to check
    /// @param _marketId the id of the market to check
    /// @param _size the size to compare against
    /// @return true if the account's position size in the given market is above the given '_size`, false otherwise
    function isPositionSizeAbove(
        uint128 _accountId,
        uint128 _marketId,
        int128 _size
    ) external view returns (bool);

    /// @notice determine if the account's (identified by the given accountId)
    /// position size in the given market is below a given size
    /// @param _accountId the id of the account to check
    /// @param _marketId the id of the market to check
    /// @param _size the size to compare against
    /// @return true if the account's position size in the given market is below the given '_size`, false otherwise
    function isPositionSizeBelow(
        uint128 _accountId,
        uint128 _marketId,
        int128 _size
    ) external view returns (bool);

    /// @notice determine if the order fee for the given market and size delta is above a given fee
    /// @param _marketId the id of the market to check
    /// @param _sizeDelta the size delta to check
    /// @param _fee the fee to compare against
    /// @return true if the order fee for the given market and size delta is below the given `_fee`, false otherwise
    function isOrderFeeBelow(uint128 _marketId, int128 _sizeDelta, uint256 _fee)
        external
        view
        returns (bool);
}

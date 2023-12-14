// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";

/// @title Kwenta Smart Margin v3: Engine Interface]
/// @notice Conditional Order -> "co"
/// @author JaredBorders (jaredborders@pm.me)
interface IEngine {
    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/

    /// @notice order details used to create an order on a perps market within a co
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

    /// @notice co
    struct ConditionalOrder {
        // order details
        OrderDetails orderDetails;
        // address of the signer of the order
        address signer;
        // a means to prevent replay attacks and identify the order
        uint256 nonce;
        // option to require all extra conditions to be verified on-chain
        bool requireVerified;
        // address that can execute the order *if* requireVerified is false
        address trustedExecutor;
        // max fee denominated in ETH that can be paid to the executor
        uint256 maxExecutorFee;
        // array of extra conditions to be met on-chain *if* requireVerified is true
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

    /// @notice thrown when attempting to debit an account with insufficient balance
    error InsufficientEthBalance();

    /// @notice thrown when attempting to transfer eth fails
    error EthTransferFailed();

    /// @notice thrown when attempting to deposit eth into an account that does not exist
    error AccountDoesNotExist();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted when the account owner or delegate successfully invalidates an unordered nonce
    /// @param accountId the id of the account that was invalidated
    /// @param word the word position of the bitmap that was invalidated
    /// @param mask the mask used to invalidate the bitmap
    event UnorderedNonceInvalidation(
        uint128 indexed accountId, uint256 word, uint256 mask
    );

    /// @notice emitted when eth is deposited into the engine and credited to an account
    /// @param accountId the id of the account that was credited
    /// @param amount the amount of eth deposited
    event EthDeposit(uint128 indexed accountId, uint256 amount);

    /// @notice emitted when eth is withdrawn from the engine and debited from an account
    /// @param accountId the id of the account that was debited
    /// @param amount the amount of eth withdrawn
    event EthWithdraw(uint128 indexed accountId, uint256 amount);

    /// @notice emitted when a co is executed
    /// @param order the order commited to the perps market
    /// that was defined in the co
    /// @param executorFee the fee paid to the executor for executing the co
    event ConditionalOrderExecuted(
        IPerpsMarketProxy.Data order, uint256 synthetixFees, uint256 executorFee
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
                             ETH MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice deposit eth into the engine and credit the account identified by the accountId
    /// @param _accountId the id of the account to credit
    function depositEth(uint128 _accountId) external payable;

    /// @notice withdraw eth from the engine and debit the account identified by the accountId
    /// @param _accountId the id of the account to debit
    /// @param _amount the amount of eth to withdraw
    function withdrawEth(uint128 _accountId, uint256 _amount) external;

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

    /// Conditional Orders
    ///
    /// tldr:
    /// co's are signed objects that define an async order
    /// and several conditions that must be met for the order to be executed.
    ///
    /// deep dive:
    /// co's are composed of 8 main parts:
    /// 1. The async order details which are defined in the OrderDetails struct
    ///    (the order that is being submitted to Synthetix perps v3 market)
    /// 2. isReduceOnly flag which indicates if the order can *only* reduce
    ///    the position size and is also defined in the OrderDetails struct
    /// 3. The signer of the co which must be the account owner or delegate
    ///    and is included in the ConditionalOrder struct.
    ///    THIS DATA IS ALWAYS CHECKED ON-CHAIN
    /// 4. The nonce of the co which is included in the ConditionalOrder struct.
    ///    The nonce is specific to the account id and is used to prevent replay attacks.
    ///    The nonce is not specific to an address, but rather an account id.
    ///    THIS DATA IS ALWAYS CHECKED ON-CHAIN
    /// 5. The requireVerified flag which is included in the ConditionalOrder struct.
    ///    If requireVerified is true, all conditions defined in the co must be satisfied *on-chain*
    ///    at the time of execution.
    ///    If requireVerified is false, the co can ONLY be executed by the trustedExecutor and the conditions
    ///    array is effectively unused (in the on-chain context).
    ///    Notice that the conditions are not checked on-chain if requireVerified is false but are
    ///    expected to be checked off-chain by the trustedExecutor. This saves a significant amount gas
    ///    and allows the trusted executor to employ additional sophisticated methods of ensuring
    ///    best trade execution.
    /// 6. The trustedExecutor address which is included in the ConditionalOrder struct.
    ///    The trustedExecutor is the address that can execute the co if requireVerified is false.
    ///    If requireVerified is true, the trustedExecutor is ignored/not used and
    ///    the conditions array becomes the source of verification imposed on-chain.
    /// 7. The maxExecutorFee which is included in the ConditionalOrder struct.
    ///    The maxExecutorFee is the maximum fee that can be imposed by the address that
    ///    successfully executes the co (trustedExecutor or not). This max fee is denominated in ETH and is
    ///    enforced on-chain. If the maxExecutorFee is greater than the fee specified
    ///    by the executor, the co will *not* be executed.
    /// 8. The conditions which are included in the ConditionalOrder struct.
    ///    Conditions are encoded function selectors and parameters that are used to determine
    ///    if the co can be executed. Conditions are checked on-chain if requireVerified is true.
    ///    If requireVerified is false, conditions are expected to be checked off-chain by the trustedExecutor.
    ///    Conditions are stictly limited selectors defined in the Engine contract
    ///    (ex: isTimestampBeforeSelector, isPriceAboveSelector, etc.)
    ///
    ///
    /// co's are not creaed on-chain. They are composed and signed off-chain. The signature
    /// is then passed to the Engine contract along with the co. The Engine contract then
    /// verifies the signature along with many other "things" to determine if the co can be executed.
    ///
    /// Checklist:
    /// In *every* case of co execution, the logic of validating the co is:
    ///
    /// 1. Check if the fee specified by the executor is less than or equal to the maxExecutorFee
    /// 2. Check if the account has sufficient ETH credit to pay the fee
    ///    (see ETH MANAGEMENT for how that can be accomplished)
    /// 3. Check if the nonce has been used (see NONCE MANAGEMENT for how that can be accomplished)
    /// 4. Check if the signer is the owner or delegate of the account
    /// 5. Check if the signature is valid for the given co and signer
    /// 6. IF requireVerified is true, check if all conditions are met
    ///    ELSE IF requireVerified is false, check if the msg.sender is the trustedExecutor
    ///
    /// All of these checks are carried out via a call to the Engine's canExecute function
    /// that returns true or false. If canExecute returns true, the co can be executed assuming the context of
    /// the check(s) is/are reliable.
    /// If canExecute returns false, the co cannot be executed.
    /// This function is expected to be used off-chain to determine if the co can be executed.
    /// It will be called within the Engine's execute function to determine if the co can be executed
    /// and if it returns true, the co will be executed. If it returns false, the co will not be executed
    /// and the transaction will revert with CannotExecuteOrder().
    ///
    /// note: It is recommended to attempt simulating the co execution prior to submission
    /// or employ some other sophisticated stratgey to mitigate the risk of submitting a co that
    /// cannot be executed due to internal Synthetix v3 scenarios/contexts that are *unpredictable*.
    ///
    /// The Engine contract does not store co's. It only stores the nonceBitmaps for each account.
    /// The Engine does hold and account for ETH credit and can modify the ETH credit of an account.
    ///
    /// ETH Management:
    /// With the introduction of co's, the Engine contract now holds ETH credit for accounts.
    /// Using collateral to pay for fees is not ideal due to accounting risks associated with
    /// orders that are close to max leverage. To mitigate this risk, the Engine contract
    /// holds ETH credit for accounts. This ETH credit is used to pay for fees.
    /// Furthermore, given the multi-colateral nature of the protocol, the Engine contract
    /// does not need to handle scenarios where an account does not have sufficient
    /// snxUSD collateral to pay the fee.
    ///
    /// Finally, the current approach to implementing Account Abstraction via ERC-4337
    /// requires traders deposit ETH to the "protocol" prior to trading. This ETH can be
    /// multipurposed to pay for fees. This is the approach taken by the Engine contract.

    /// @custom:docs for more in-depth documentation of co mechanism,
    /// please refer to https://github.com/Kwenta/smart-margin-v3/wiki/Conditional-Orders

    /// @notice execute a co
    /// @param _co the co
    /// @param _signature the signature of the co
    /// @param _fee the fee paid to executor for the co
    /// @return retOrder the order committed
    /// @return synthetixFees the fees paid for the order to Synthetix
    ///         and *NOT* the fees paid to the executor
    function execute(
        ConditionalOrder calldata _co,
        bytes calldata _signature,
        uint256 _fee
    )
        external
        returns (IPerpsMarketProxy.Data memory retOrder, uint256 synthetixFees);

    /// @notice checks if the co can be executed
    /// @param _co the co which details the order to be executed and the conditions to be met
    /// @param _signature the signature of the co
    /// @param _fee the executor specified fee for the executing the co
    /// @dev if the fee is greater than the maxExecutorFee defined in the co,
    /// or if the account lacks sufficient ETH credit to pay the fee, canExecute will return false
    /// @custom:warning this function may return false-positive results in the case the underlying Synthetix Perps v3
    /// market is in a state that is not predictable (ex: unpredictable updates to the market's simulated fill price)
    /// @return true if the order can be executed, false otherwise
    function canExecute(
        ConditionalOrder calldata _co,
        bytes calldata _signature,
        uint256 _fee
    ) external view returns (bool);

    /// @notice verify the co signer is the owner or delegate of the account
    /// @param _co the co
    /// @return true if the signer is the owner or delegate of the account
    function verifySigner(ConditionalOrder calldata _co)
        external
        view
        returns (bool);

    /// @notice verify the signature of the co
    /// @param _co the co
    /// @param _signature the signature of the co
    /// @return true if the signature is valid
    function verifySignature(
        ConditionalOrder calldata _co,
        bytes calldata _signature
    ) external view returns (bool);

    /// @notice verify array of conditions defined in the co
    /// @dev
    ///     1. all conditions are defined by the co creator
    ///     2. conditions are encoded function selectors and parameters
    ///     3. each function defined in the condition contract must return a truthy value
    ///     4. internally, staticcall is used to protect against malicious conditions
    /// @param _co the co
    /// @return true if all conditions are met
    function verifyConditions(ConditionalOrder calldata _co)
        external
        view
        returns (bool);

    /*//////////////////////////////////////////////////////////////
                               CONDITIONS
    //////////////////////////////////////////////////////////////*/

    /// DISCLAIMER:
    /// Take note that if a trusted party is authorized to execute a co, then the trader
    /// does not actually need to specify any conditions. In a contrived example, the trader
    /// could simply "tell" the trusted party to execute the co if the price of ETH is above/below some number.
    /// The trusted party would then check the price of ETH (via whatever method deemed necessary)
    /// and execute the co.
    /// This is a very simple example, but it illustrates the flexibility of the co
    /// along with the degree of trust that will be placed in the trusted party.
    /// Finally, it is expected that despite the conditions array being unnecessary in *this* context,
    /// it will likely still be used to provide additional context to the trusted party.
    /// However, *again*, it is not required.

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

    /// @notice determine if the simulated fill price is above a given price
    /// @dev relies on Synthetix Perps v3 market's simulated fill price
    /// @param _marketId id a market used to check the price of the
    /// underlying asset of that market (i.e. ETH Perp Market -> ETH)
    /// @param _price the price to compare against
    /// @return true if the simulated fill price is above the given `_price`, false otherwise
    function isPriceAbove(uint128 _marketId, uint256 _price)
        external
        view
        returns (bool);

    /// @notice determine if the simulated fill price is below a given price
    /// @dev relies on Synthetix Perps v3 market's simulated fill price
    /// @param _marketId id a market used to check the price of the
    /// underlying asset of that market (i.e. ETH Perp Market -> ETH)
    /// @param _price the price to compare against
    /// @return true if the simulated fill price is below the given `_price`, false otherwise
    function isPriceBelow(uint128 _marketId, uint256 _price)
        external
        view
        returns (bool);

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

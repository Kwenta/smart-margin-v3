// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

contract SynthetixV3Errors {
    enum SettlementStrategyType {PYTH}

    error OffchainLookup(
        address sender,
        string[] urls,
        bytes callData,
        bytes4 callbackFunction,
        bytes extraData
    );
    error InvalidVerificationResponse();
    error InvalidSettlementStrategy(SettlementStrategyType strategyType);
    error MinimumSettlementAmountNotMet(uint256 minimum, uint256 actual);
    error SettlementStrategyNotFound(SettlementStrategyType strategyType);
    error InvalidFeeCollectorInterface(address invalidFeeCollector);
    error InvalidReferrerShareRatio(uint256 shareRatioD18);
    error NotEligibleForLiquidation(uint128 accountId);
    error InvalidAmountDelta(int256 amountDelta);
    error InvalidArgument();
    error InvalidUpdateDataSource();
    error InvalidUpdateData();
    error InsufficientFee();
    error NoFreshUpdate();
    error PriceFeedNotFoundWithinRange();
    error PriceFeedNotFound();
    error StalePrice();
    error InvalidWormholeVaa();
    error InvalidGovernanceMessage();
    error InvalidGovernanceTarget();
    error InvalidGovernanceDataSource();
    error OldGovernanceMessage();
    error SettlementWindowNotOpen(uint256 timestamp, uint256 settlementTime);
    error SettlementWindowExpired(
        uint256 timestamp, uint256 settlementTime, uint256 settlementExpiration
    );
    error SettlementWindowNotExpired(
        uint256 timestamp, uint256 settlementTime, uint256 settlementExpiration
    );
    error OrderNotValid();
    error AcceptablePriceExceeded(uint256 fillPrice, uint256 acceptablePrice);
    error PendingOrderExists();
    error ZeroSizeOrder();
    error InsufficientMargin(int256 availableMargin, uint256 minMargin);
    error MaxCollateralExceeded(
        uint128 synthMarketId,
        uint256 maxAmount,
        uint256 collateralAmount,
        uint256 depositAmount
    );
    error SynthNotEnabledForCollateral(uint128 synthMarketId);
    error InsufficientCollateral(
        uint128 synthMarketId, uint256 collateralAmount, uint256 withdrawAmount
    );
    error InsufficientCollateralAvailableForWithdraw(
        uint256 available, uint256 required
    );
    error InsufficientMarginError(uint256 leftover);
    error AccountLiquidatable(uint128 accountId);
    error MaxPositionsPerAccountReached(uint128 maxPositionsPerAccount);
    error MaxCollateralsPerAccountReached(uint128 maxCollateralsPerAccount);
    error InvalidMarket(uint128 marketId);
    error PriceFeedNotSet(uint128 marketId);
    error MarketAlreadyExists(uint128 marketId);
    error MaxOpenInterestReached(
        uint128 marketId, uint256 maxMarketSize, int256 newSideSize
    );
    error PerpsMarketNotInitialized();
    error PerpsMarketAlreadyInitialized();
    error PriceDeviationToleranceExceeded(uint256 deviation, uint256 tolerance);
    error ExceedsMaxUsdAmount(uint256 maxUsdAmount, uint256 usdAmountCharged);
    error ExceedsMaxSynthAmount(
        uint256 maxSynthAmount, uint256 synthAmountCharged
    );
    error InsufficientAmountReceived(uint256 expected, uint256 current);
    error InvalidPrices();
    error InvalidWrapperFees();
    error NotNominated(address addr);
    error InvalidMarketOwner();
    error InsufficientSharesAmount(uint256 expected, uint256 actual);
    error OutsideSettlementWindow(
        uint256 timestamp, uint256 startTime, uint256 expirationTime
    );
    error IneligibleForCancellation(uint256 timestamp, uint256 expirationTime);
    error OrderAlreadySettled(uint256 asyncOrderId, uint256 settledAt);
    error InvalidClaim(uint256 asyncOrderId);
    error OnlyAccountTokenProxy(address origin);
    error PermissionNotGranted(
        uint128 accountId, bytes32 permission, address user
    );
    error InvalidAccountId(uint128 accountId);
    error Unauthorized(address addr);
    error CannotSelfApprove(address addr);
    error InvalidTransferRecipient(address addr);
    error InvalidOwner(address addr);
    error TokenDoesNotExist(uint256 id);
    error TokenAlreadyMinted(uint256 id);
    error PermissionDenied(
        uint128 accountId, bytes32 permission, address target
    );
    error InsufficientBalance(uint256 required, uint256 existing);
    error InsufficientSynthCollateral(
        uint128 synthMarketId, uint256 collateralAmount, uint256 withdrawAmount
    );
}

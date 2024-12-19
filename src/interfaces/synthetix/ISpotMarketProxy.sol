// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

/// @title Consolidated Spot Market Proxy Interface
/// @notice Responsible for interacting with Synthetix v3 spot markets
/// @author Synthetix
interface ISpotMarketProxy {
    /*//////////////////////////////////////////////////////////////
                            MARKET INTERFACE
    //////////////////////////////////////////////////////////////*/

    /// @notice returns a human-readable name for a given market
    function name(uint128 marketId) external view returns (string memory);

    /*//////////////////////////////////////////////////////////////
                       SPOT MARKET FACTORY MODULE
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the proxy address of the synth for the provided marketId
    /// @dev Uses associated systems module to retrieve the token address.
    /// @param marketId id of the market
    /// @return synthAddress address of the proxy for the synth
    function getSynth(uint128 marketId)
        external
        view
        returns (address synthAddress);

    /*//////////////////////////////////////////////////////////////
                             WRAPPER MODULE
    //////////////////////////////////////////////////////////////*/

    struct Data {
        uint256 fixedFees;
        uint256 utilizationFees;
        int256 skewFees;
        int256 wrapperFees;
    }

    /// @notice Wraps the specified amount and returns similar value of synth
    /// minus the fees.
    /// @dev Fees are collected from the user by way of the contract returning
    /// less synth than specified amount of collateral.
    /// @param marketId Id of the market used for the trade.
    /// @param wrapAmount Amount of collateral to wrap.  This amount gets
    /// deposited into the market collateral manager.
    /// @param minAmountReceived The minimum amount of synths the trader is
    /// expected to receive, otherwise the transaction will revert.
    /// @return amountToMint Amount of synth returned to user.
    /// @return fees breakdown of all fees. in this case, only wrapper fees are
    /// returned.
    function wrap(
        uint128 marketId,
        uint256 wrapAmount,
        uint256 minAmountReceived
    ) external returns (uint256 amountToMint, Data memory fees);

    /// @notice Unwraps the synth and returns similar value of collateral minus
    /// the fees.
    /// @dev Transfers the specified synth, collects fees through configured fee
    /// collector, returns collateral minus fees to trader.
    /// @param marketId Id of the market used for the trade.
    /// @param unwrapAmount Amount of synth trader is unwrapping.
    /// @param minAmountReceived The minimum amount of collateral the trader is
    /// expected to receive, otherwise the transaction will revert.
    /// @return returnCollateralAmount Amount of collateral returned.
    /// @return fees breakdown of all fees. in this case, only wrapper fees are
    /// returned.
    function unwrap(
        uint128 marketId,
        uint256 unwrapAmount,
        uint256 minAmountReceived
    ) external returns (uint256 returnCollateralAmount, Data memory fees);

    /*//////////////////////////////////////////////////////////////
                          ATOMIC ORDER MODULE
    //////////////////////////////////////////////////////////////*/

    /// @notice Initiates a buy trade returning synth for the specified
    /// amountUsd.
    /// @dev Transfers the specified amountUsd, collects fees through configured
    /// fee collector, returns synth to the trader.
    /// @dev Leftover fees not collected get deposited into the market manager
    /// to improve market PnL.
    /// @dev Uses the buyFeedId configured for the market.
    /// @param marketId Id of the market used for the trade.
    /// @param usdAmount Amount of snxUSD trader is providing allowance for the
    /// trade.
    /// @param minAmountReceived Min Amount of synth is expected the trader to
    /// receive otherwise the transaction will revert.
    /// @param referrer Optional address of the referrer, for fee share
    /// @return synthAmount Synth received on the trade based on amount provided
    /// by trader.
    /// @return fees breakdown of all the fees incurred for the transaction.
    function buy(
        uint128 marketId,
        uint256 usdAmount,
        uint256 minAmountReceived,
        address referrer
    ) external returns (uint256 synthAmount, Data memory fees);

    /// @notice Initiates a sell trade returning snxUSD for the specified amount
    /// of synth (sellAmount)
    /// @dev Transfers the specified synth, collects fees through configured fee
    /// collector, returns snxUSD to the trader.
    /// @dev Leftover fees not collected get deposited into the market manager
    /// to improve market PnL.
    /// @param marketId Id of the market used for the trade.
    /// @param synthAmount Amount of synth provided by trader for trade into
    /// snxUSD.
    /// @param minUsdAmount Min Amount of snxUSD trader expects to receive for
    /// the trade
    /// @param referrer Optional address of the referrer, for fee share
    /// @return usdAmountReceived Amount of snxUSD returned to user
    /// @return fees breakdown of all the fees incurred for the transaction.
    function sell(
        uint128 marketId,
        uint256 synthAmount,
        uint256 minUsdAmount,
        address referrer
    ) external returns (uint256 usdAmountReceived, Data memory fees);
}

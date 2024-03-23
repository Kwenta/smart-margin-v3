# Exclusive order flow potential MEV opportunities

MEV is a measure of the profit a miner (or validator, sequencer, etc.) can make through their ability to arbitrarily include, exclude, or re-order transactions within the blocks they produce.

As part of conditional orders execution process in Smart Margin v3, orders executed by a trusted executor will not undergo on-chain verification (see more details on the [wiki](https://github.com/Kwenta/smart-margin-v3/wiki/Conditional-Orders)), making it less gas-intensive and cheaper.

Auditors pointed out that given the exclusive nature of conditional orders that are marked as only executable by trusted parties, MEV opportunities exist. This document identifies what these might be and solutions to prevent exclusive order flow from being exploited by ourselves.
## 
Having exclusive order flow can be a bad thing because the ability to arbitrarily include or exclude a transaction can create MEV. In our case, Kwenta trusted executor could potentially choose to include or exclude specific conditional orders thus creating potential MEV.
In order to extract this MEV, Kwenta would have to act as a trader themselves (or make a third party profitable).

In all of the examples below, we will assume that all orders are executed through the trustedExecutor.

## Exploiting Market price manipulation

Let's say Kwenta opens a long trade on asset A (same logic can be applied for short trades) then proceeds excluding every short order on asset A only accepting long orders. This would impact market price positively, allowing Kwenta to close their trade with profits, thus extracting value from excluding specific orders.

## Exploiting Funding Rates

Let's say that Kwenta opens a short trade on asset B, then proceeds to only accept long orders on this asset (up until maximum OI which does not trigger asymmetric funding rate [sip-354](https://sips.synthetix.io/sips/sip-354/)), making skew long. In this setup, funding goes up, then if every order on asset B is excluded, Kwenta could exploit the funding rate by maintaining their short position.

## Priority fee reordering

Although this is something that would be hard to exploit and that is not currently possible in the current smart contract as we only cover base fees with maxExecutorFee, technically, using all of the maximum fee that can be paid to the executor(uint256 maxExecutorFee) to add a priority fee on top of the base fee could exploit some MEV through a reordering of transactions.

## Risk assessment

The presented MEV opportunities are informative for users to understand how the trusted executor could act as a bad actor but do not represent real risks, as little value would be hard to exploit from these, and Kwenta would immediatly loose its users trust in doing so, which would be detrimental to Kwenta's interests as the protocol generates revenue on transactions fee.

Kwenta uses a trusted executor so that no on-chain verification occurs, making it less gas-intensive and cheaper for the user, this is why the user relies on the trustedExecutor to execute the order only when the off-chain conditions are satisfied.

These MEV opportunities could be alleviated by making contracts immutable, but contracts need to remain upgradeable as Synthetix evolves and some adaptation is required.

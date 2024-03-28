# Kwenta's Smart Margin v3 Security Review

Internal security review of Kwenta's Smart Margin v3 performed during the Kwenta Mentorship Program by Flocast.

# Introduction

Smart Margin v3 (SMv3) offers advanced tools for trading Synthetix v3 derivatives. It introduces a monolithic "Engine" contract. This Engine is the hub for managing various components, including collateral, async orders, and conditional orders. It's designed to seamlessly integrate future features, consolidating them into a single, efficient contract.

Users should have a Synthetix v3 account that they can integrate with Kwenta SMv3 by granting it administrative permissions (which can be revoked at any time by the user).

SMv3 handles conditional order with an off-chain submission process where the conditional order is then registered in a database. Kwenta's backend infrastructure then continuously monitors the conditions set in the ConditionalOrder conditions, and upon fulfillment of these conditions, an executor attempts to execute the conditional order.

It is worth to mention that if the trustedExecutor is used (which should be the case for all the conditional orders made through Kwenta Front End), no on-chain verification occurs before execution, making it less gas-intensive and cheaper for the user.

Details about this process can be found [here](https://github.com/Kwenta/smart-margin-v3/wiki/Conditional-Orders).

Additional documentation on SMv3 is accessible on the project's [wiki](https://github.com/Kwenta/smart-margin-v3/wiki).


## Actors

* Users : Synthetix v3 account owners or Delegates
* Synthetix v3
* Zap


`Engine.sol` is Upgradable by the pDao multisig
> See [Upgradability in Smart Margin v3](https://github.com/Kwenta/smart-margin-v3/wiki/What-is-Smart-Margin#upgradability-in-smart-margin-v3)

## Assumptions

* The trader relies on the `ConditionalOrder.trustedExecutor` to execute the order only when the off-chain conditions are satisfied and in a reasonable time.
* The integrated Synthetix and Pyth systems are assumed to be fully trusted by the users.
* Zap provides fair $sUSD / $USDC exchange.
* Delegates given permission to execute conditional orders are trusted by the account owner.
* The user trusts Kwenta that no malicious upgrades will be made on the SMv3 Engine.


## Scope

The following smart contracts at commit [`cacb85b`](https://github.com/Kwenta/smart-margin-v3/tree/cacb85bd4c913a85c6bc978b1e8cde2585cee19a) were in the scope of the audit:

```
src/
├── Engine.sol
├── interfaces
│   ├── IEngine.sol
│   ├── synthetix
│   │   ├── IERC7412.sol
│   │   ├── IPerpsMarketProxy.sol
│   │   └── ISpotMarketProxy.sol
│   └── tokens
│       └── IERC20.sol
├── libraries
│   ├── ConditionalOrderHashLib.sol
│   ├── MathLib.sol
│   └── SignatureCheckerLib.sol
└── utils
    ├── EIP712.sol
    ├── EIP7412.sol
    └── MulticallablePayable.sol
```

# Risk Classification

| Severity               | Impact: High | Impact: Medium | Impact: Low |
| ---------------------- | ------------ | -------------- | ----------- |
| **Likelihood: High**   | :red_circle: Critical     | :orange_circle: High           | :yellow_circle: Medium      |
| **Likelihood: Medium** | :orange_circle: High         | :yellow_circle: Medium         | :large_blue_circle: Low         |
| **Likelihood: Low**    | :yellow_circle: Medium       | :large_blue_circle: Low            | :large_blue_circle: Low         |

1 Impact
• High - leads to a loss of a significant portion (>10%) of assets in the protocol, or significant harm to a majority of users.
• Medium - global losses <10% or losses to only a subset of users, but still unacceptable.
• Low - losses will be annoying but bearable--applies to things like griefing attacks that can be easily repaired or even gas inefficiencies.

2 Likelihood
• High - almost certain to happen, easy to perform, or not easy but highly incentivized
• Medium - only conditionally possible or incentivized, but still relatively likely
• Low - requires stars to align, or little-to-no incentive

3 Action required for severity levels
• Critical - Must fix as soon as possible (if already deployed)
• High - Must fix (before deployment if not already deployed)
• Medium - Should fix
• Low - Could fix

----------

# :large_blue_circle: [L-01] isSameSign different result for comparison of negative/positive numbers with zero may lead to unexpected behavior in other uses.

### Severity

- Low Risk

### Context:
[src/libraries/MathLib.sol](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/libraries/MathLib.sol)

## Description

Currently, the `isSameSign` function returns false for (x = 0) and (y < 0) but does return true for (x = 0) and (y > 0).
```
/// @notice determines if input numbers have the same sign
    /// @dev asserts that both numbers are not zero
    /// @param x signed 128-bit number
    /// @param y signed 128-bit number
    /// @return true if same sign, false otherwise
    function isSameSign(int128 x, int128 y) internal pure returns (bool) {
        assert(x != 0 && y != 0);
        return (x ^ y) >= 0;
    }
```

As of right now, `isSameSign` is only used in the Engine.execute function for reduce only orders, where this behaviour is not exploitable, but if `isSameSign` was to be used in other scenario, this could lead to unexpected behaviour.


## Recommendations

1. If this is the desired behaviour, consider changing to `(x ^ y) > -1` for gas optimisation.
2. Otherwise, change the function to `return (x == 0) || (y == 0) || (x > 0) == (y > 0);` so that it has the same result for both positive/negative comparisons with zero.
3. Additionally, `assert(x != 0 && y != 0);` can be removed as it is currently checked that both parameters are not zero before using `isSameSign`, and it is not a check that might be pertinent for other uses of `isSameSign`.

My recommendation is that `isSameSign` should return true when either x or y is zero, and that we should get rid of the assert.

> Note : Recommendation 2 is also what is done by Synthetix v3 MathUtil library

----------

# :black_circle: [N-01] Execution ordering of and() may lead to unexpected behavior in future compiler versions.


### Context:
[src/libraries/SignatureCheckerLib.sol](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/libraries/SignatureCheckerLib.sol)

## Description

The arguments of and(arg1, arg2) are expected to always execute in the order of arg2 and then arg1. SignatureCheckerLib uses this behavior to ensure the staticcall is executed before loading memory at location d. (We can see the comment *This must be placed at the end of the `and` clause*)
```
                isValid := and(
                    // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                    eq(mload(d), f),
                    // Whether the staticcall does not revert.
                    // This must be placed at the end of the `and` clause,
                    // as the arguments are evaluated from right to left.
                    staticcall(
                        gas(), // Remaining gas.
                        signer, // The `signer` address.
                        m, // Offset of calldata in memory.
                        add(signature.length, 0x64), // Length of calldata in memory.
                        d, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                )
```

If the eq statement was executed before the staticcall, the memory location d might not contain the expected value yet, leading to incorrect comparison results.


No anomalies of execution reordering seem to currently exist on different compiler versions, however this behavior is not guaranteed to be permanent across future compiler versions.


## Recommendations

Performing the staticcall before the and() may prevent possible execution reordering.

```
                let s := staticcall(
                        gas(), // Remaining gas.
                        signer, // The `signer` address.
                        m, // Offset of calldata in memory.
                        add(signature.length, 0x64), // Length of calldata in memory.
                        d, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                isValid := and(
                    // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                    eq(mload(d), f),
                    // Whether the staticcall does not revert.
                    s
                )
```

> Note : This behaviour is also used by different established projects, the recommandation is more to bring attention to what should be done if execution behaviour was to change in future compiler versions

----------

# Overall Analysis

----------

`MulticallablePayable.sol`

Similar implementations are used by other projects like [Solady](`https://github.com/vectorized/solady/blob/main/src/utils/Multicallable.sol`), but they made the `multicall` function deliberately non-payable to guard against double-spending.

In our implementation `multicall` is payable, it should be noted that inside a delegatecall, msg.sender and msg.value are persisted, so we need to make sure message.value is not used several times to prevent multiple spending (See: https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong).

Currently message.value is only used in `EIP7412.fulfillOracleQuery()`, where it is not exploitable, but in case of future updates, Kwenta should be very **cautious** during potential future updates that no other function using message.value is implemented, as this is a likely entry point for exploits.


----------
`Engine.sol`

External entry points like `modifyCollateral` or Authentication have different tests confirming expected behaviour, there was no edge case identified during the audit

Conditional Order Execution has sufficient validation that no undesirable behaviours were indentified.

Similar Nonce Management is used by [Uniswap](https://docs.uniswap.org/contracts/permit2/reference/signature-transfer#nonce-schema), plus the code is well documented with detailed example on how the nounce schema works.


----------

Gas optimisations are done thoroughly, for example in `EIP712.sol` the contract caches hashes and the domain separator during construction, reducing gas costs for subsequent calls, in `ConditionalOrderHashLib.sol` pre-computed type hashes for `OrderDetails` and `ConditionalOrder` for gas optimisation.

Project was designed with gas optimisations in mind, and no consequent additional gas optimisations were found during the internal audit.

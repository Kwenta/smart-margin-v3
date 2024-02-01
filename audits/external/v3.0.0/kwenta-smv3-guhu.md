# Security review of Kwenta's Smart Margin v3

A time-boxed security review of **Kwenta**'s **Smart Margin v3** was conducted by **Guhu**, with a focus on the security aspects of the smart contract implementation.

Disclaimer: A smart contract security review does not guarantee a complete absence of vulnerabilities. This was a time-bound effort to provide the highest value possible within the available time. Subsequent security reviews, a bug bounty program, and on-chain monitoring are highly recommended.

## About **Guhu**

[**Guhu**](https://twitter.com/Guhu95) is an independent security researcher with extensive experience in smart contract audits and an established bug bounty track record on Immunefi's [leaderboard](https://immunefi.com/leaderboard/). This engagement has followed previous work [reviewing Kwenta's Staking V2](https://gist.github.com/guhu95/3330fad8e6417b567a3787f86392ae32).

# Overview of **Smart Margin v3** system

Smart Margin v3 aims to enhance the trading experience for Kwenta users by offering improved tools for trading on [Synthetix V3 Perps](https://docs.synthetix.io/v/v3/for-perp-integrators/perps-v3). 

For the most detailed and comprehensive documentation, please refer to [the wiki section of the implementation repository](https://github.com/Kwenta/smart-margin-v3/wiki/What-is-Smart-Margin). Below is a high-level overview.

The core of the system is a Conditional Order (CO) management flow, developed to integrate with and be deployed alongside Synthetix V3 Perps on Optimism and Base deployments. This setup allows third-party executors to submit orders on behalf of an account using a message signed off-chain by either the account owner or a delegate.

To provide permissionless access for the community, a public off-chain database will be used to store and propagate the users' COs to potential executors.

The system also incorporates [ERC-2771](https://eips.ethereum.org/EIPS/eip-2771), enabling transaction relaying through another contract that similarly utilizes off-chain signatures. This approach involves a relayer executing batches of forwarding requests through a forwader contract.

For clarity, the system's two off-chain mechanisms are distinguished as follows: the terms "execution," "executor," and "order" refer to the first - Conditional Orders - mechanism, while "forwarding," "relayer," and "forwarding request" to the second - ERC-2771 Meta Transactions.

A custom ERC-2771 forwarder contract will be deployed as part of the system, intended to be the trusted forwarder by the Engine. This forwarder's unique feature is its ability to aggregate on-chain calls from a user in addition to forwarding off-chain requests, referred to as "aggregation."

These mechanisms can operate together; for example, an executor might sign, then relay their own execution call requests, containing a user's signed COs, through the call aggregation mechanism.

#### Status Update

Following the audit, ERC-2771, trusted forwarder, and relayer were removed. `MulticallPayable` was added.

## General Observations

The overall quality of the reviewed codebase is very high: the code is well-structured, thought-out, thoroughly documented, and adheres to industry best practices. The deployment process is well-organized, scripted, automated, clearly documented, and fork-tested where possible. The provided accompanying documentation is, as mentioned earlier, detailed and comprehensive, aiding significantly in the review process.

Notably, the code facilitates a highly complex system involving various actors and interactions. These include two systems of off-chain signature-based delegated execution, a multicall-like call aggregation system, a public DB with a mempool-like structure, support for smart contract wallets (ERC-1271), off-chain oracle query support (ERC-7412), integration with the Synthetix accounts and Perps markets system, and a distinct custom ERC-2771 system. Each of these components is complex in its own right, and their combination significantly increases the overall system complexity, thereby expanding the surface area for potential vulnerabilities.

Furthermore, the code incorporates several relatively uncommon patterns that contribute code complexity to the aforementioned systems complexity. These include the use of unordered nonces for COs, the use of bitmaps for nonce implementation, and custom signature verification code based on the [experimental and gas-optimized Solady library](https://github.com/vectorized/solady/) . 

#### Status Update

Following the audit, ERC-2771, trusted forwarder, and relayer were removed. `MulticallPayable` was added.

## Privileged Roles & Actors

All contracts in scope are unowned and immutable. 

The integrated Synthetix and Pyth systems are owned, upgradeable, and are assumed to be fully trusted by the users.

## Scope

The following smart contracts at commit [`d684448`](https://github.com/Kwenta/smart-margin-v3/tree/d684448e097b0bb575dd24e9ce3353f71f1122c5) were in the scope of the audit:

```
src
├── Engine.sol
├── interfaces
│   ├── IEngine.sol
│   ├── oracles
│   │   └── IPyth.sol
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
    └── EIP7412.sol

lib/trusted-multicall-forwarder/
├── src
    └── TrustedMulticallForwarder.sol
```

## Mitigation Review

The team's fixes were reviewed at commit [`f61f61c`](https://github.com/Kwenta/smart-margin-v3/tree/f61f61ca7e38d48bf197072aa2287e0316e2e20b).

---

# Findings Summary

| |Title|Severity|Status|
|---|---|---|---|
|:red_circle:|**[C-01] Incorrect Handling of `allowFailure` in `aggregate3Value` Traps ETH**|Critical|:white_check_mark: Fixed|
|:yellow_circle:|**[M-01] Exploitable Stale Orders Due to Unordered Nonces**|Medium|:mag: Partially Fixed|
|:yellow_circle:|**[M-02] DoS of Off-Chain Conditional Order Infrastructure**|Medium|:scroll: Noted|
|:yellow_circle:|**[M-03] Arbitrary Destination Calls Allow Exploiting or Griefing the Relayer**|Medium|:white_check_mark: Fixed|
|:yellow_circle:|**[M-04] `fulfillOracleQuery` with Non-Zero ETH Value Will Revert or Trap ETH**|Medium|:white_check_mark: Fixed|
|:yellow_circle:|**[M-05] Executor Griefing Mitigations are Insufficient**|Medium|:mag: Partially Fixed|
|:yellow_circle:|**[M-06] Trusted Forwarder Cannot Be Revoked**|Medium|:white_check_mark: Fixed|
|:yellow_circle:|**[M-07] Public Database of COs Allows L2 MEV**|Medium|:scroll: Noted|
|:yellow_circle:|**[M-08] `aggregate3Value` Lack of Refund Traps ETH**|Medium|:white_check_mark: Fixed|
|:yellow_circle:|**[M-09] `aggregate3Value` Allows Draining Contract ETH Balance**|Medium|:white_check_mark: Fixed|
|:yellow_circle:|**[M-10] Aggregated Forwarding Allows Dangerous Arbitrary Calls**|Medium|:white_check_mark: Fixed|
|:yellow_circle:|**[M-11] Testing Coverage Gaps**|Medium|:mag: Partially Fixed|
|:large_blue_circle:|**[L-01] ETH Withdrawal in `Execute` Does Not Properly Follow CEI and Allows Reentrancy**|Low|:white_check_mark: Fixed|
|:large_blue_circle:|**[L-02] Unnecessary `payable` Attribute in `aggregate3` Traps ETH**|Low|:white_check_mark: Fixed|
|:large_blue_circle:|**[L-03] Unnecessarily Complex Gas Optimizations for L2 Code**|Low|:scroll: Noted|
|:large_blue_circle:|**[L-04] Confusing and Error-Prone Failure Semantics of `canExecute`**|Low|:scroll: Noted|
|:large_blue_circle:|**[L-05] Nonce Invalidation UX is Error-Prone**|Low|:scroll: Noted|
|:large_blue_circle:|**[L-06] Inclusion of Full External Interfaces Is Error-Prone**|Low|:white_check_mark: Fixed|
|:large_blue_circle:|**[L-07] Insufficient Input Validation During Permission Checks**|Low|:white_check_mark: Fixed|
|:large_blue_circle:|**[L-08] Unexpected Revert in `isSameSign`**|Low|:white_check_mark: Fixed|
|:large_blue_circle:|**[L-09] `executeBatch` Allows Gas Griefing the Relayer**|Low|:white_check_mark: Fixed|
|:black_circle:|**[N-01] Maximum Number of Conditions May Be Too Restrictive**|Note|:scroll: Noted|
|:black_circle:|**[N-02] Variable Shadowing in Constructor**|Note|:white_check_mark: Fixed|
|:black_circle:|**[N-03] Naming Suggestions**|Note|:scroll: Noted|
|:black_circle:|**[N-04] Documentation Issues**|Note|:white_check_mark: Fixed|
|:black_circle:|**[N-05] `invalidateUnorderedNonces` Invalidates Unusable Bitmaps**|Note|:scroll: Noted|
|:black_circle:|**[N-06] Pyth Optimism Oracle Implementation Unverified**|Note|:mag: Partially Fixed|
|:black_circle:|**[N-07] Unneeded Condition Selector Constants**|Note|:white_check_mark: Fixed|
|:black_circle:|**[N-08] Unnecessary Casting Post Bit Shift**|Note|:white_check_mark: Fixed|
|:black_circle:|**[N-09] Unused Code**|Note|:white_check_mark: Fixed|
|:black_circle:|**[N-10] Price Condition Oracle Choice May Be Incorrect**|Note|:white_check_mark: Fixed|

# Severity Classification Framework

| Severity               | Impact: High | Impact: Medium | Impact: Low |
| ---------------------- | ------------ | -------------- | ----------- |
| **Likelihood: High**   | :red_circle: Critical     | :orange_circle: High           | :yellow_circle: Medium      |
| **Likelihood: Medium** | :orange_circle: High         | :yellow_circle: Medium         | :large_blue_circle: Low         |
| **Likelihood: Low**    | :yellow_circle: Medium       | :large_blue_circle: Low            | :large_blue_circle: Low         |

----------

# :red_circle: [C-01] Incorrect Handling of `allowFailure` in `aggregate3Value` Traps ETH

## Description

The [`aggregate3Value` function has an incorrect implementation of the `allowFailure` check](https://github.com/Synthetixio/trusted-multicall-forwarder/blob/77ff94f448d8b747c4c297b38a54a80dbe5c9054/src/TrustedMulticallForwarder.sol#L203C17-L203C35). The current logic will cause a revert when `allowFailure` is set, which is contrary to the intended behavior. Conversely, when `allowFailure` is false, the function should revert if the call fails, but instead it will succeed.

This will lead to loss of provided ETH from any EOAs, or non-delegatecall contract callers, because failed calls will not revert the transaction and the ETH will not be refunded. Consequently, this ETH will remain trapped in the contact.

As the this functionality may be used by `Engine` users to fund their `ETH` balances during multi-transaction flows, the likelihood of this method being called with non-zero ETH value is high.

### Severity

- Impact: High
- Likelihood: High

## Recommendations

Reverse the logic of the `allowFailure` check within the `aggregate3Value` function. Additionally, ensure all execution branches are thoroughly covered by tests.

## Status: :white_check_mark: Fixed

The trusted forwarder and the usage of ERC-2771 were removed.

----------

# :yellow_circle: [M-01] Exploitable Stale Orders Due to Unordered Nonces

## Description

Multiple orders signed by a user can remain valid concurrently due to the use of unordered nonces. This situation can lead to the existence of stale orders for an account. Although users have the option to cancel these orders via `invalidateUnorderedNonces`, this function must [be called by the account owner or delegates](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L211). Additionally, users may be disincentivized from using this function diligently and consistently due to the additional operational overhead, transaction costs, or the need to sign extra relayer messages.

There are several scenarios due to which executable stale orders are likely to occur:

- Multiple conflicting orders where redundant ones are not cancelled.
- Incorrectly specified ordered assumed to be not executable that become executable at a later time.
- Orders not relayed/executed by executors or relayers due to non-profitability, malfunction, or malice.
- Orders set with incorrect conditions for a trusted executor, and not revoked due to trust.

Additionally, invalidation efforts might also be ineffective due to:

- User errors or UI/UX issues in invalidating nonces, e.g., the [need to specify index and mask instead of a nonce](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L208-L209).
- Reliance on possibly flawed off-chain nonce and order tracking.
- Inability to determine past nonces due to off-chain database malfunctions or DoS attacks (M-02).

Consequently, stale orders can be used to extract ETH fees and order related MEV (slippage extraction), with a high likelihood of occurrence due to multiple scenarios and diverse user behavior.

Moreover, increased impact scenarios may include:

- Compromise of the trusted executor's hot-wallet enabling execution of all accumulated past stale orders [without performing condition checks](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L548).
- Fee extraction without `commitOrder` submission in cases of [`reduceOnly` no-op orders in specific situations](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L478-L483) like closed/liquidated positions, position side changes, or large `sizeDelta`.

Even though some diligent users may use the `isTimestampBefore` condition as an expiry, it isn't mandatory. Additionally, the usage of this condition does not mitigate the scenario of a future trusted executor hot-wallet compromise or short-term exploitation within the expiry window.

### Severity

- All three combination of medium severity are possible (impact-likelihood being: low-high, medium-medium, and high-low).

## Recommendations

1. Implement an incremental nonce mapping by `accountId` and `marketId` to automatically invalidate stale orders and reduce execution ambiguity. While invalidation will be automatic, a user invoked invalidation function may still be desired to allow users to avoid conflicting valid orders.
3. Introduce a mandatory expiry field in orders to protect from long term scenarios such as the trusted executor compromise.
4. Replace no-op order executions with reverts for incorrectly specified orders.

## Status: :mag: Partially Fixed

No-op order executions were replaced with reverts.

----------

# :yellow_circle: [M-02] DoS of Off-Chain Conditional Order Infrastructure

## Description

In the current system, users submit signed Conditional Orders (COs) through the Front-End, which are then populated into a public database, similar to a blockchain mempool. This setup demands robust DoS protection to prevent overload by spam requests, which are less costly to submit than to reject. Both the database and the executor/keeper nodes need to efficiently discard malicious requests while retaining all valid ones, in order to reduce the accumulation of stale orders (and exacerbating M-01).

Optimally, spam requests should be rejectable based solely on off-chain processing, avoiding expensive and slow RPC requests to access contract views. However, the current system has vulnerabilities that hinder effective spam rejection:

1. Unordered nonces allow an essentially infinite amount of valid signed COs for an `accountId`, necessitating validation and selection. Tracking invalidated nonces is feasible off-chain, but the space for valid nonces remains virtually infinite. Additionally, any signer can submit a spam order for any account due to the use of `accountId`s as the main identifier.
2. Rejecting a signer-order mismatch for an account relies on the Synthetix account system for permission validation. This requires an RPC call for validating authorization or relying on, possibly delayed, off-chain tracking of account permissions via event indexing. However, Synthetix's [`revokeAllPermissions` does not emit the necessary events](https://github.com/Synthetixio/synthetix-v3/blob/553e2472dad0645ff7a4fcbb2cbf07693f59dfbf/protocol/synthetix/contracts/storage/AccountRBAC.sol#L106-L118), making indexing non-viable.
3. Signer-signature mismatches are difficult to reject due to the use of [ERC-1271 requiring a contract call](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/libraries/SignatureCheckerLib.sol#L75-L82) for short signature or in case of ECDSA rejection. Verifying signatures necessitates an RPC request, adding to the complexity of rejection. A workaround could involve validating only for signers with non-zero code contracts, but attackers can still deploy numerous contracts to exploit this system.

These weaknesses allow attackers to flood the system with fake orders, either for profit (monopolizing execution, fee extraction, order-flow control, or price manipulation of KWENTA or SNX tokens) or for malicious intent without direct financial gain.

### Severity

- Impact: Medium
- Likelihood: Medium

## Recommendations

1. Implement a conventional incremental nonce system to significantly limit the range of valid nonces.
2. Remove ERC-1271 support in favor of ECDSA validation that can be validated off-chain. Additionally, opt for the more battle-tested OpenZeppelin ECDSA library instead of the custom implementation based on the experimental and optimization oriented Solady library. This will also add consistency with the forwarder contract.
3. While Synthetix permissions might still require on-chain validation for accuracy, ensure they can be efficiently and promptly validated off-chain in DoS scenarios by ensuring proper event emission in Synthetix contracts.

## Status: :scroll: Noted

----------

# :yellow_circle: [M-03] Arbitrary Destination Calls Allow Exploiting or Griefing the Relayer

## Description

[`EIP7412`'s `fulfillOracleQuery`](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/utils/EIP7412.sol#L18C9-L21) permits any caller to call any contract. If relayed through the trusted forwarder, the relayer bears the gas costs. This setup is exploitable if the relayer is subsidized by Kwenta or incentivized without directly accounting for transaction gas costs. Attackers could utilize this to perform various on-chain actions at the relayer's expense, such as minting gas tokens, fulfilling keeper requests, deploying contracts, or executing Conditional Orders without incurring gas costs.

Moreover, this functionality can be used to grief the relayer, even without direct profit to the attacker. Malicious payloads can be designed to run out of gas under specific conditions (e.g., using `tx.gasprice` to determine if they are being simulated off-chain), consuming excessive resources or failing during on-chain execution.

Since the function signature allows arbitrary data, it can also be misused to publish any data on-chain, catering to external data availability needs on L2 and L1. Restricting the gas passed to the internal call might not fully mitigate the issue due to the L1 data costs incurred by the external call. Additionally, off-chain heuristics employed by the relayer for filtering malicious payloads could require ongoing maintenance and monitoring, not be reliable, or create an opaque censorship point in a mechanism intended to be trustless.

Similarly, the ETH withdrawal function [`_withdrawEth` also permits calling an arbitrary destination](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L196) contract in a relayed transaction, creating similar vulnerabilities, though with a more complex setup.

### Severity

- Impact: Medium
- Likelihood: Medium

## Recommendations

1. For `fulfillOracleQuery`, implement an allowlist of callable targets. Set this allowlist at construction if targets are known in advance, or for dynamic targets manage it through a separate contract, controlled by governance. This approach minimally increases trust assumptions, as possible censorship by the allowlist can be circumvented outside the Engine.
2. For `_withdrawEth`, prevent calling the function via the relayer by reverting if `msg.sender == trustedForwarder()`. This measure is practical as both the account owner withdrawing ETH and the executor submitting an order do not require the use of the relayer. Alternatively, if necessary for executors to submit `execute` requests via the relayer, limit the gas usage of the withdrawal call to reduce abuse profitability.
## Status: :white_check_mark: Fixed

The trusted forwarder and the usage of ERC-2771 were removed.

----------

# :yellow_circle: [M-04] `fulfillOracleQuery` with Non-Zero ETH Value Will Revert or Trap ETH

## Description

[`EIP7412`'s `fulfillOracleQuery`](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/utils/EIP7412.sol#L21) is marked as `payable` but fails to forward `msg.value` to its destination. Additionally, the contract cannot accept any ETH refunds from such calls.

There are several implications of this behavior:

1. If `msg.value` is non-zero, and the internal call does not revert, ETH will become permanently trapped in the contract. This scenario is possible if the destination call does not require ETH, or executes as a [non-ERC-compliant no-op](https://eips.ethereum.org/EIPS/eip-7412#specification) instead of reverting.
2. If the callee expects ETH, the absence of forwarded `msg.value` will cause the call to revert if the calle is ERC-compliant. This will prevent the function from being usable.
3. If the code is amended to properly forward  `msg.value` , and the callee refunds any ETH during its call, the call will also revert due to the absence of a `receive` or payable `fallback` function in the contract. Implementing such a function would necessitate an additional ETH management mechanisms for refunding the original senders. Although the [ERC specifies](https://eips.ethereum.org/EIPS/eip-7412#specification) such refunds as optional, it is a common and sensible pattern, and should be expected if the implementation of the callee is unknown. 
   
### Severity

- Impact: Low
- Likelihood: High

## Recommendations

1. Revert on non-zero `msg.value` if the expected targets will not require ETH fees. This approach prevents the accidental trapping of ETH in the contract.
2. Alternatively, If the targets do expect ETH, modify the contract to pass `msg.value` in the call to the destination. Additionally, implement a payable empty `fallback` method to credit refunded ETH to the ERC-2771 `_msgSender()`, and create a method for later withdrawal of these funds. Note that Solidity's `receive()` will not work for ETH sent from the forwarder contract because the calldata will not be empty.

## Status: :white_check_mark: Fixed

`fulfillOracleQuery` now forwards `msg.value` without handling refunds.

----------

# :yellow_circle: [M-05] Executor Griefing Mitigations are Insufficient

## Description

Griefing of the executor by the signer is a significant concern in the system, with several existing mitigations:

- [Limiting the number of conditions to prevent Out of Gas (OOG)](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/interfaces/IEngine.sol#L62-L63) during condition validation.
- [Validating condition selectors](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L601-L602) to match only boolean views, preventing OOG via specifying a mutative function.
- The [design of the `canExecute` view for off-chain checks by executors](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/interfaces/IEngine.sol#L272C37-L274C95) to assess the executability of an order before submission.

However, these mitigations are inadequate, as an unexpected revert of execution following a successful `canExecute` query can result in wasted gas for executors with no compensation. Several reverts paths are possible:

1. A [multitude of checks in the Perps market during `commitOrder` call](https://github.com/Synthetixio/synthetix-v3/blob/553e2472dad0645ff7a4fcbb2cbf07693f59dfbf/markets/perps-market/contracts/storage/AsyncOrder.sol#L275-L359), where failure leads to a revert. Examples include insufficient margin, zero size order, lack of `Engine` admin permissions, existing pending orders, high price delta, and various market and account state combinations. Consequently, only simulation of the submission can predict non-reversion.
2. The possibility of panic reverts in cases [of `reduceOnly` and `sizeDelta=0`](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L482) due to [`Math`'s `isSameSign` assert](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/libraries/MathLib.sol#L65).
3. The potential for OOG reverts in [ERC-1271 signature verification](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/libraries/SignatureCheckerLib.sol#L75-L82), which might pass off-chain but fail on-chain maliciously.

As a result, executor griefing remains a plausible risk, and reliance on `canExecute` off-chain may create a false sense of security and add operational complexity. Attackers could submit griefing orders to deplete competitors' gas for profit and to monopolize fee and order MEV extraction. Alternatively, this could be done without profit motives, as off-chain order submissions are free.

### Severity

- Impact: Medium
- Likelihood: Medium

## Recommendations

1. Clearly document the reverting behavior of `execute` and the limitations of `canExecute` in guaranteeing successful execution.
2. Encourage the use of simulation of the `execute` transaction to reduce chances of reverts.
3. Address potential reverts outside `commitOrder` by ensuring `isSameSign` does not revert and by removing ERC-1271 support. This will help in mitigating the risks associated with these specific failure points. Additionally, as previously mentioned, opt for the more battle-tested OpenZeppelin ECDSA library instead of the current signature verification implementation.

## Status: :mag: Partially Fixed

Recommended documentation was added and `isSameSign` revert is prevented.

----------

# :yellow_circle: [M-06] Trusted Forwarder Cannot Be Revoked

## Description

The trusted forwarder plays a crucial role in the system, acting as a key trust assumption with considerable added attack surface. It is not only a custom implementation of the standard but also introduces [complex functionality, aggregating multiple direct forwarded](https://github.com/Synthetixio/trusted-multicall-forwarder/blob/77ff94f448d8b747c4c297b38a54a80dbe5c9054/src/TrustedMulticallForwarder.sol#L54-L218) calls, and the original signature-based request execution in the same contract. The `Engine` fully trusts the forwarder for call authentication, and users, in turn, place their trust in the `Engine` with admin control of their Synthetix accounts.

However, the [immutable configuration](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L108) of the trusted forwarder poses a significant risk. If vulnerabilities are discovered in its design or implementation, no single emergency action currently exists to revoke its trusted status. In such a scenario, users would need to individually revoke admin permissions to their Synthetix accounts, a process most may not complete in time, potentially leading to the loss of their collateral. Furthermore, any ETH balances controlled by the `Engine` could remain at risk regardless of any emergency actions in the Synthetix system.

### Severity

- Impact: High
- Likelihood: Low

## Recommendations

1. Implement an emergency function accessible to a designated `forwarderCircuitBreaker` address, ideally assigned to a governance controlled contract. This function should allow the revocation of the trusted forwarder.
2. Implement the revocation by overriding the `trustedForwarder` view, which will depend on the `forwarderRevoked` storage flag. This change will not significantly alter the trust assumptions of the `Engine`, as actions possible through the forwarder would still be possible via direct interaction.

## Status: :white_check_mark: Fixed

The trusted forwarder and the usage of ERC-2771 were removed.

----------

# :yellow_circle: [M-07] Public Database of COs Allows L2 MEV

## Description

The public database storing Conditional Orders essentially acts as a public "mempool" for Perps COs on L2. This exposure allows anyone to extract MEV that was previously accessible only to the trusted L2 sequencer, which likely avoided overt and hostile MEV extraction.

With the new setup, users and user interfaces, which were previously less concerned about hostile MEV on L2, now need to be vigilant. They must ensure that relay requests and COs are structured to leak minimal and predictable value. 

For example, there's a risk of order sandwiching, particularly for orders with high slippage tolerance, and during volatile periods. Attackers can strategically place orders around these to be settled in a sequence based on their submission time, thereby extracting value by manipulating the `fillPrice`. Furthermore, an attacker controlling a dominant settlement keeper can submit sandwich orders simultaneously with a user's order all in one block, subsequently settling them in a manner that maximizes their own profit.

### Severity

- Impact: Medium
- Likelihood: Medium

## Recommendations

1. Promote cautious setting of order parameters, both through documentation and checks within the UI.
2. Actively monitor CO MEV-related activities to identify new forms of value extraction, and implement additional off-chain and on-chain countermeasures to mitigate them.
3. Consult with some trusted members of the MEV community to determine additional weaknesses and mitigations.

## Status: :scroll: Noted

----------

# :yellow_circle: [M-08] `aggregate3Value` Lack of Refund Traps ETH

## Description

In the [`aggregate3Value` function](https://github.com/Synthetixio/trusted-multicall-forwarder/blob/77ff94f448d8b747c4c297b38a54a80dbe5c9054/src/TrustedMulticallForwarder.sol#L182-L218), there is no mechanism to refund any unsent ETH back to the caller in case of calls that are allowed to fail. This function, adapted from [Multicall3](https://github.com/mds1/multicall/blob/main/src/Multicall3.sol), is designed to be primarily `delegatecalled` by contracts rather than being used directly by EOAs. The lack of a refund process for unspent ETH means that any excess ETH sent to the function will be permanently trapped.

However, as `allowFailure` needs to be `true` (assuming the C-01 is fixed). This is unlikely to be the case for ETH bearing calls from EOAs, which reduces the likelihood to low.

### Severity

- Impact: High
- Likelihood: Low

## Recommendations

Implement a refund mechanism to return unsent ETH to the caller.

## Status: :white_check_mark: Fixed

The trusted forwarder and the usage of ERC-2771 were removed.

----------

# :yellow_circle: [M-09] `aggregate3Value` Allows Draining Contract ETH Balance

## Description

The `aggregate3Value` function, [contrary to its documentation](https://github.com/Synthetixio/trusted-multicall-forwarder/blob/77ff94f448d8b747c4c297b38a54a80dbe5c9054/src/TrustedMulticallForwarder.sol#L195-L196), is vulnerable to overflow in [the `valAccumulator` variable](https://github.com/Synthetixio/trusted-multicall-forwarder/blob/77ff94f448d8b747c4c297b38a54a80dbe5c9054/src/TrustedMulticallForwarder.sol#L198). This is because a call with with an incorrectly set `msg.value` fails in the callee context instead of in the caller context. For instance, the `test` function in the below example contract does not revert despite trying to send an impossibly large amount of ETH:


```solidity
contract Test {
    function test() external {
        address(0).call{value: type(uint).max}("");
    } 
}
```


This flaw enables the extraction of the full contract balance through a two-call payload with zero `msg.value`:

- One call sends out the balance to the caller.
- The other call triggers an overflow of `valAccumulator` back to 0, with `allowFailure` set to true.

Since `valAccumulator` and `msg.value` both equal 0 at the end of the call, their [equivalence check passes](https://github.com/Synthetixio/trusted-multicall-forwarder/blob/77ff94f448d8b747c4c297b38a54a80dbe5c9054/src/TrustedMulticallForwarder.sol#L215). 

Although the contract is not intended to hold any ETH balance, [mirroring its `Multicall3` inspiration](https://github.com/mds1/multicall#batch-contract-writes), this should still be fixed. This is because the original assumptions of `Multicall3` are already violated since the contract combines `Multicall3` and the stateful `ERC2771Forwarder`. Similarly, future modifications could result in a contract with an ETH balance, or some other contract can borrow the vulnerable implementation.

Interestingly, this vulnerability could also allow the extraction of any trapped ETH due to the multiple trapped ETH findings. However, this does not diminish their severity, as the ETH will be lost to the original senders, and it doesn't make sense to justify the presence of one vulnerability by another.

There is also a potential risk involving reentrant calls and malicious relayer payloads affecting not just the resting ETH balance but also `msg.value` internal accounting. Although a specific exploit scenario wasn't identified, the possibility remains, particularly with future code updates.

### Severity

- Impact: High
- Likelihood: Low

## Recommendations

Remove the `unchecked` keyword.

## Status: :white_check_mark: Fixed

The trusted forwarder and the usage of ERC-2771 were removed.

----------

# :yellow_circle: [M-10] Aggregated Forwarding Allows Dangerous Arbitrary Calls

## Description

The [aggregation methods in `TrustedMulticallForwarder` ](TrustedMulticallForwarder)append [`msg.sender` to the calldata for ERC-2771 forwarding](https://github.com/Synthetixio/trusted-multicall-forwarder/blob/77ff94f448d8b747c4c297b38a54a80dbe5c9054/src/TrustedMulticallForwarder.sol#L66) but fail to verify whether the target address expects these forwarding requests. Consequently, the contract enables arbitrary call execution, rather than just serving as a trusted forwarder. This oversight leads to several security concerns:

- Token approvals mistakenly granted to the forwarder (instead of e.g., the `Engine`) can be easily exploited, leading to the draining of user token balances. Such inadvertent approvals are plausible, given the perceived safety, and semantic proximity, of these Kwenta-deployed contracts.
- Complex reentrancy paths are introduced, allowing nested relaying and forwarding calls among various aggregation and execution methods. Although no specific attack vector was identified, the extensive flexibility of these methods makes excluding potential vulnerabilities uncertain.
- The possibility of exploiting vulnerabilities in forwarding targets, which do not anticipate requests from this contract, also cannot be ruled out.

In contrast, the `ERC2771Forwarder` base contract checks that all forwarded calls are to targets implementing the ERC-2771 context and that this forwarder is trusted by them. It [verifies the `trustedForwarder` view on the target returns the correct address](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/metatx/ERC2771Forwarder.sol#L305-L321) [during `_validate`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/metatx/ERC2771Forwarder.sol#L205), effectively preventing calls to any targets not expecting them.

### Severity

- Impact: High
- Likelihood: Low

## Recommendations

Implement the necessary `_isTrustedByTarget` check for all forwarding calls. Depending on the failure handling parameters of the request, either revert or skip the call if the check returns `false`.

## Status: :white_check_mark: Fixed

The trusted forwarder and the usage of ERC-2771 were removed.

----------

# :yellow_circle: [M-11] Testing Coverage Gaps

## Description

The `TrustedMulticallForwarder` currently has branch test coverage of only 30%, and function coverage of only 15%, significantly below the industry standard. This is particularly concerning given the complex nature of the functionality, which is borrowed and heavily modified from `Multicall3` source code and repurposed for different uses. The lack of comprehensive testing is a major factor contributing to the various issues identified in this report (e.g., C-01, M-08, M-09, M-10), and it increases the probability of additional severe vulnerabilities in current code, or due to future modifications.

Additionally, in the case of the `Engine` contract, there are also some test coverage gaps, resulting in a branch coverage of 83%. These gaps are primarily due to inadequate testing of various revert scenarios and conditional branches. 

Furthermore, there are minor coverage issues in `EIP712`.

### Severity

- Impact: High
- Likelihood: Low

## Recommendations

1. Ensure full branch coverage for all Solidity code. 
2. Ensure thorough fork test coverage for both Optimism and Base Synthetix deployments (which are final stages of development at the time of writing), since important and nuanced differences are likely to exist between those deployment targets.
## Status: :mag: Partially Fixed

The trusted forwarder and the usage of ERC-2771 were removed, improving the coverage significantly. Additional tests were added to raise the `Engine`'s branch coverage to 92%. EIP712 and further coverage improvements are planned in the future.

----------
# :large_blue_circle: [L-01] ETH Withdrawal in `Execute` Does Not Properly Follow CEI and Allows Reentrancy

The implementation of the `execute` function currently [calls `_withdrawEth` before completing all internal and external trusted effects](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L464), deviating from the Checks-Effects-Interactions (CEI) pattern. This ordering creates a reentrancy vector in the contract. 

Additionally, if incremental nonces are implemented as recommended, the current order may lead to the reversal of the user intended order of nonce execution. While this is also possible now, the unerdered nature of the nonces make his non consequential. However, even if unordered nonces are retained, adhering to the CEI pattern is recommended as a best practice for contract security.

## Recommendations

1. Rearrange the `execute` function to call `_withdrawEth` only after all mutative actions and trusted external calls have been completed.
2. Avoid using no-ops in execution. This change will also help align the incentives of the executor and the signer towards successful order submission.

## Status: :white_check_mark: Fixed

The fee mechanism now uses `sUSD` instead of ETH, which does not currently allow reentrancy. However, as `sUSD` is upgradeable, a reentrancy through an ERC-677/ERC-777 like callback introduced in a future update cannot be ruled out, and following CEI is recommended.

----------

# :large_blue_circle: [L-02] Unnecessary `payable` Attribute in `aggregate3` Traps ETH

The [`aggregate3` function is marked as `payable`](https://github.com/Synthetixio/trusted-multicall-forwarder/blob/77ff94f448d8b747c4c297b38a54a80dbe5c9054/src/TrustedMulticallForwarder.sol#L154C9-L154C16), which is unnecessary and traps any `msg.value` provided to the call. This implementation is a [gas optimization carried over from Multicall3](https://github.com/mds1/multicall#gas-golfing-tricks-and-optimizations), optimized for L1, but is unnecessary and error-prone on L2. 

## Recommendations

The `payable` keyword should be removed, similarly to the other unneeded uses of it which were removed in the contract. 

## Status: :white_check_mark: Fixed

The trusted forwarder and the usage of ERC-2771 were removed.

----------
# :large_blue_circle: [L-03] Unnecessarily Complex Gas Optimizations for L2 Code

The current codebase exhibits a strong preference for execution gas optimization, often at the expense of code complexity, maintainability, and safety. This approach might not be justified on L2 environment, compared to practices employed for L1 contracts, since execution gas costs are considerably lower, but complexity and maintainability risks remain. 

Examples of such optimizations include:

- Adopting [code](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/libraries/SignatureCheckerLib.sol) [from](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/utils/EIP712.sol) Solady, which is primarily [experimental](https://github.com/Vectorized/solady#safety), assembly-based, and focused on gas savings. Additionally, the code is further altered from its original library version.
- Utilizing [unchecked blocks for index increments](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L619-L621) in loops and calculations.
- Employing [bitmaps for nonce management](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L226-L310).
- Implementing [bit twiddling techniques for mathematical operations](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/libraries/MathLib.sol#L13-L45), despite more readable implementations available in OZ or [Synthetix code](https://github.com/Synthetixio/synthetix-v3/blob/553e2472dad0645ff7a4fcbb2cbf07693f59dfbf/markets/spot-market/contracts/utils/MathUtil.sol#L31-L33). Specifically, [`abs256` can be borroewed from OZ's `SignedMath` ](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/utils/math/SignedMath.sol#L37-L43), while for `abs128` - upcasting , using `abs256`, and downcasting - can be more readable. 

## Recommendations

In situations where deployment is exclusively on L2s, it is advisable to forego these minor, yet intricate optimizations. Instead consider preferring safer, simpler, and more readable alternatives.

## Status: :scroll: Noted

----------

# :large_blue_circle: [L-04] Confusing and Error-Prone Failure Semantics of `canExecute`


The `canExecute` view, in most negative scenarios, returns false. However, it can also revert in certain situations, leading to a confusing and error-prone interface for off-chain integrations. This inconsistency is particularly problematic in gas griefing and DoS scenarios, as detailed in other findings. 

Specifically, it can revert due to [out-of-gas during ERC-1721 signature check](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/libraries/SignatureCheckerLib.sol#L76) and for [errors like `InvalidConditionSelector` or `MaxConditionSizeExceeded` in `verifyConditions`](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L591-L623).

## Recommendations

1. Modify `verifyConditions` to consistently return false instead of reverting.
2. To prevent OOG reverts, consider either removing support for ERC-1271 or forwarding only a limited amount of gas when calling it.

## Status: :scroll: Noted

----------

# :large_blue_circle: [L-05] Nonce Invalidation UX is Error-Prone

The `invalidateUnorderedNonces` function's UX is error-prone as it requires passing [indices and bit masks](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L208-L209) instead of nonces. Conversely, the contract lacks a `noncesToBitmaps` view, which would expose `_bitmapPositions` for correctly translating the nonces to indices and masks. This can result in both bad UX, and incorrectly invalidating or not invalidating nonces.

## Recommendations

Modify the function to expect a nonce array or range, and calculate the mask internally. Alternatively, introduce a `noncesToBitmaps` view function to allow correct calculation of input arguments for the invalidation function. 

## Status: :scroll: Noted

----------

# :large_blue_circle: [L-06] Inclusion of Full External Interfaces Is Error-Prone

Including full external interfaces from evolving systems like [Synthetix](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/interfaces/synthetix/IPerpsMarketProxy.sol) and [Pyth](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/interfaces/oracles/IPyth.sol) can lead to future errors. Interfaces should be limited to only the used parts to avoid future dependency on outdated functions or incorrect integration based on stale documentation. Instead, trim down external integrated interfaces to include only the components currently in use. 

## Status: :white_check_mark: Fixed

----------

# :large_blue_circle: [L-07] Insufficient Input Validation During Permission Checks

## Description

The [`isAccountOwner` function](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L126-L133), which calls [`getAccountOwner`](https://github.com/Synthetixio/synthetix-v3/blob/553e2472dad0645ff7a4fcbb2cbf07693f59dfbf/protocol/synthetix/contracts/modules/core/AccountModule.sol#L190), and [`_isAccountOwnerOrDelegate` function](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L147-L155), which [calls `isAuthorized`](https://github.com/Synthetixio/synthetix-v3/blob/553e2472dad0645ff7a4fcbb2cbf07693f59dfbf/protocol/synthetix/contracts/modules/core/AccountModule.sol#L127), will both incorrectly return true for a `_caller` that is `address(0)` if the account for the `accountId` is uninitialized. This occurs due to a lack of validation for the existence of the account, treating uninitialized default values as if they were initialized. Although this does not currently impact the system due to checks in other functions, it represents a shortcoming in integrating with the Synthetix codebase.

While the scenario of an actual caller being `address(0)` is typically impossible, it could arise in cases involving off-chain-specified signer validation or vulnerabilities related to meta-transactions. Furthermore, this issue breaks the semantics of these `Engine` functions, potentially leading to unsafe assumptions in future code modifications.

## Recommendation

Modify both `isAccountOwner` and `_isAccountOwnerOrDelegate` functions to return false if `_caller == address(0)`. 

## Status: :white_check_mark: Fixed

----------

# :large_blue_circle: [L-08] Unexpected Revert in `isSameSign`


The current implementation of `isSameSign` in the `MathLib` library uses an [`assert` statement](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/libraries/MathLib.sol#L65), which may lead to unexpected reverts. Refactor the code to remove the `assert` statement, possibly utilizing [Synthetix's `sameSide` implementation](https://github.com/Synthetixio/synthetix-v3/blob/553e2472dad0645ff7a4fcbb2cbf07693f59dfbf/markets/spot-market/contracts/utils/MathUtil.sol#L31-L33) instead.

## Status: :white_check_mark: Fixed

The function's usage was modified to prevent the revert.

----------
# :large_blue_circle: [L-09] `executeBatch` Allows Gas Griefing the Relayer

## Description

The [additional variant of `executeBatch` function](https://github.com/Synthetixio/trusted-multicall-forwarder/blob/77ff94f448d8b747c4c297b38a54a80dbe5c9054/src/TrustedMulticallForwarder.sol#L225) in the current implementation introduces vulnerabilities by deviating from the base contract's safety mechanisms:

1. **Delayed `gasleft` Check**: The check for remaining gas is [performed after copying and decoding the returndata](https://github.com/Synthetixio/trusted-multicall-forwarder/blob/77ff94f448d8b747c4c297b38a54a80dbe5c9054/src/TrustedMulticallForwarder.sol#L260-L261) in a solidity low level call, and not immediately following an assembly call. This deviation from the original implementation, which applies the 63/64th rule [as noted in its documentation](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/metatx/ERC2771Forwarder.sol#L335C8-L336C76), results in incorrect behavior. The additional gas consumption during copying and decoding can falsely trigger a revert, making this check ineffective.
    
2. **Returndata-bomb Vulnerability**: [Storing the returndata of each call in memory](https://github.com/Synthetixio/trusted-multicall-forwarder/blob/77ff94f448d8b747c4c297b38a54a80dbe5c9054/src/TrustedMulticallForwarder.sol#L255) exposes the relayer to [returndata-bombing](https://github.com/nine-december/returndatabomb-study), especially when processing batched requests. The quadratic memory expansion costs exacerbate the issue. Although the callee bears memory expansion costs for their returndata bomb, the caller (relayer) incurs significantly higher costs both due to increased `returndatacopy` opcode costs (original returndata-bomb issue) and the prior memory expansion from storing previous calls' returndata in this context's memory. This represents a gas griefing vector against the relayer and potentially against other users' requests in the same batch with a malicious payload or several.
    
The original intention behind returndata returns from the aggregation methods [in `Multicall3`](https://github.com/mds1/multicall#usage) is for off-chain static `Multicall` usage and delegatecalling contracts. However, these use cases may not be necessary in the context of off-chain signed message relaying for `executeBatch`.

## Recommendations

Reevaluate the necessity of the added variant of `executeBatch` for the contract's intended use cases. 

## Status: :white_check_mark: Fixed

The trusted forwarder and the usage of ERC-2771 were removed.

----------

# :black_circle: [N-01] Maximum Number of Conditions May Be Too Restrictive

The current maximum allowed number of conditions for order execution might be insufficient for complex scenarios. Users are likely to require at least five basic safety conditions, such as expiry time, two conditions for position size restriction, a fee limit restriction, and a price restriction. This leaves only three conditions for additional preferences. Consequently, users may need more flexibility to trigger orders based on other factors like other asset prices, other accounts' positions, or more specific time windows. A better tradeoff can likely be achieved with a slightly higher number, for example 10 conditions.

## Status: :scroll: Noted

----------
# :black_circle: [N-02] Variable Shadowing in Constructor

The[ `_trustedForwarder` constructor argument](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L108C22-L108C39) shadows an [immutable variable](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/552cffde563e83043a6c3a35012b626a25eba775/contracts/metatx/ERC2771Context.sol#L19C31-L19C48) of the same name. 

## Status: :white_check_mark: Fixed

The usage of ERC-2771 were removed.

----------

# :black_circle: [N-03] Naming Suggestions

1. [Rename `execute` ](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L440C14-L440C21) and all the related functions and variables to use the `submit` terminology to better disambiguate from other specific (e.g., `execute` in the forwarder context) and genetic usages of "execute".
2. Change [`_withdrawEth`'s `_caller` argument](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L187C25-L187C32) to `_to` for clarity it indicating the recipient of the withdrawal, since the passed address is not guaranteed or needed to be a caller in that function's context.

## Status: :scroll: Noted

----------

# :black_circle: [N-04] Documentation Issues

1. The comment ["only the account owner can withdraw collateral" ](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L397)is misplaced.
2. Change ["execute the order"](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L503) to "commit the order" for accuracy.
3. The comment[ "an incrementing value indexed per order" ](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/interfaces/IEngine.sol#L39C12-L39C51)is incorrect.
4. The comment ["If `signer` is a smart contract, the signature is validated with ERC1271"](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/libraries/SignatureCheckerLib.sol#L20C9-L21C67) is incorrect, since codezise is not checked, and instead the check is performed for any short signature or as fallback for ECDSA failure.

## Status: :white_check_mark: Fixed

----------

# :black_circle: [N-05] `invalidateUnorderedNonces` Invalidates Unusable Bitmaps

The function `invalidateUnorderedNonces` accepts[ `_wordPos` up to `uint256`](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L208C9-L208C16), whereas the bitmaps can only be utilized up to `type(uint248).max` size.

## Status: :scroll: Noted

----------

# :black_circle: [N-06] Pyth Optimism Oracle Implementation Unverified

The Pyth Oracle implementation at [0xff1a0f4744e8582df1ae09d5611b887b6a12925c](https://optimistic.etherscan.io/address/0xff1a0f4744e8582df1ae09d5611b887b6a12925c#code) is unverified on Optimistic Etherscan at the time of the audit.

## Status: :mag: Partially Fixed

Direct Pyth oracle usage was removed. However, the Pyth oracle implementation, used indirectly by the system, remains unverified.

----------

# :black_circle: [N-07] Unneeded Condition Selector Constants

Defining[ constants for condition selectors](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L44-L60) is unnecessary and [could be inlined](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L604-L611) for improved readability.

## Status: :white_check_mark: Fixed

----------

# :black_circle: [N-08] Unnecessary Casting Post Bit Shift

[Casting to `uint248` after the `>> 8` bit shift ](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L267)operation is unnecessary.

## Status: :white_check_mark: Fixed

----------

# :black_circle: [N-09] Unused Code

-  [`isAccountDelegate` ](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L136-L145). If it is required for tests, it can be defined in the test contract extension.
- [`castU128`](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/libraries/MathLib.sol#L52-L57).
## Status: :white_check_mark: Fixed

`isAccountDelegate` remains as is useful for the FE.

----------

# :black_circle: [N-10] Price Condition Oracle Choice May Be Incorrect

The current system [employs the Pyth oracle price directly](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/Engine.sol#L660-L674) for execution conditions in trades. However, this approach has several issues:

1. **Discrepancy between Oracle and Market Prices**: The oracle price may significantly differ from the market's `fillPrice`, potentially conflicting with the user's trading intent. While the user may also set `acceptablePrice` to reflect their settlement intent more accurately, they may intend to use it for settlement, rather than for submission, or they may neglect to set it restrictively due to relying on their choice of CO conditions.
2. **Oracle Differences vs. Perps Market**: The Perps market's internal oracle might not use the Pyth feed directly, as it could be a composite of various oracles or subject to change. Furthermore, the Pyth oracle is immutably set within the `Engine`, contrasting with the dynamic nature of the Perps system. The market [does provide an `indexPrice(marketId)` function](https://github.com/Synthetixio/synthetix-v3/blob/553e2472dad0645ff7a4fcbb2cbf07693f59dfbf/markets/perps-market/contracts/modules/PerpsMarketModule.sol#L66), reflecting the internal oracle price.
3. **Issues with Confidence Interval Checks**: In volatile markets, the confidence interval condition might inadvertently prevent trades that could be intended by the user. For instance, the user may have set `priceBelow` 1000 with confidence 10, intending to buy below 1010, but even if the price drops as low as 900, as long as the confidence (volatility) will remain above 10, the trade will not be possible.

These factors make the direct use of the Pyth oracle problematic due to unpredictability, potential manipulation, and the introduction of a rigid dependency that cannot be altered.

## Recommendations

1. Utilize the [available `fillPrice` from the `computeOrderFees` function](https://github.com/Kwenta/smart-margin-v3/blob/d684448e097b0bb575dd24e9ce3353f71f1122c5/src/interfaces/synthetix/IPerpsMarketProxy.sol#L132C45-L132C54), which more accurately reflects the market price relevant to the user's intended trade.
2. Alternatively, employ [the `indexPrice` function](https://github.com/Synthetixio/synthetix-v3/blob/553e2472dad0645ff7a4fcbb2cbf07693f59dfbf/markets/perps-market/contracts/modules/PerpsMarketModule.sol#L66) to align with the oracle price used internally by the Perps market.
3. Clearly document the semantics of the selected method and highlight their potential drawbacks.

## Status: :white_check_mark: Fixed

`fillPrice` is now used.
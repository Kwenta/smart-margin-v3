# 🧱 Smart Margin v3

## TODO
/// @custom:todo
- [ ] search `@custom:todo` and handle them all!!!
- [ ] Add more details to README
- [ ] Sort all imports in alphabetical order
- [ ] Add title, description, and author to all SMv3 contracts
- [ ] Refactor `Engine.sol` into smaller modules once code complete (i.e. Base, Stats, Auth, ConditionalOrder, etc.)
- [ ] Write invariant tests 
- [ ] Trim fat (unused code) from all interfaces (e.g. IPerpsMarketProxy.sol)

[![Github Actions][gha-badge]][gha] 
[![Foundry][foundry-badge]][foundry] 
[![License: MIT][license-badge]][license]

[gha]: https://github.com/Kwenta/smart-margin-v3/actions
[gha-badge]: https://github.com/Kwenta/smart-margin-v3/actions/workflows/test.yml/badge.svg
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[license]: https://opensource.org/license/GPL-3.0/
[license-badge]:https://img.shields.io/badge/GitHub-GPL--3.0-informational

## Overview
Smart Margin v3 is the greasiest defi fly-wheel ever seen on any evm-based blockchain 🎡. Once you start interacting with it, you'll start to wonder if your metamask doubles as a stablecoin printer 🤑 🖨️. So welcome to the trenches, degen; you're in for a wild ride 🐂. 
> @custom:todo add more details that are not cringe satire

### Quick Start
> @custom:todo add more details
1. Create a new Synthetix v3 perps market account NFT
2. Give `Engine.sol` `admin` permissions
3. Start trading!

### Account/Accounts Management
> @custom:todo add more details

### Delegate Management
> @custom:todo add more details

### Conditional Orders
```solidity
struct OrderDetails {
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
}

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
```

#### Off-Chain Submission
1. When a trader decides to place a conditional order they must decide what conditions must be met for the order to be executed
2. The trader must decide whether these conditions are verified on-chain or off-chain
3. To make that distinction, the trader must set the `ConditionalOrder.requireVerified` flag to `true` or `false`
4. If `requireVerified` is set to `true`, then the conditions specified in `ConditionalOrder.conditions` must be met on-chain
5. If `requireVerified` is set to `false`, then the conditions specified in `ConditionalOrder.conditions` **will not** be verified on-chain
6. If `requireVerified` is set to `false`, then the `ConditionalOrder.trustedExecutor` must be set to the address of a trusted executor 
7. The trusted executor is the only address that can execute the order if `ConditionalOrder.requireVerified` is set to `false`
8. The trusted executor is "trusted" to only execute the order if the conditions specified in `ConditionalOrder.conditions` are met
> note, conditions are not verified on-chain if `ConditionalOrder.requireVerified` is set to `false`, and the trader trusts the `ConditionalOrder.trustedExecutor` to execute the order if the conditions are met (as observed off-chain)
9. Once the above is decided, the trader must sign the `ConditionalOrder` struct using their private key
10. The trader must then submit the signed `ConditionalOrder` to Kwenta which will be handled/stored/processed by backend infrastructure

#### Execution
1. Kwenta backend infrastructure will monitor the conditions specified in `ConditionalOrder.conditions` for the `ConditionalOrder` submitted by the trader
2. If the conditions are met, then the `ConditionalOrder` will be executed
3. If `ConditionalOrder.requireVerified` is set to `true`, then the `ConditionalOrder.conditions` will be verified on-chain prior to execution (gas-intensive; expensive)
4. If `ConditionalOrder.requireVerified` is set to `true`, then the executor can be any address
5. If `ConditionalOrder.requireVerified` is set to `false`, then the `ConditionalOrder.conditions` will not be verified on-chain prior to execution (*not* gas-intensive; cheap)
6. If `ConditionalOrder.requireVerified` is set to `false`, then the `ConditionalOrder.trustedExecutor` must be the `msg.sender` calling the `Engine.execute` function
7. Regardless of whether `ConditionalOrder.requireVerified` is set to `true` or `false`, the `ConditionalOrder` will only be executed if: 
  1. The `ConditionalOrder.nonce` is valid (i.e. the `ConditionalOrder` has not been executed before)
  2. The `ConditionalOrder.signer` is valid (i.e. the `signer` is the owner or delegate of the account identified by the `ConditionalOrder.accountId`)
  3. The provided `ConditionalOrder` signature is valid (i.e. the `ConditionalOrder` was signed by the `ConditionalOrder.signer`)
8. If the above conditions are met, then the `ConditionalOrder` will be executed and the `ConditionalOrder.nonce` will be "spent"

#### On-Chain Fees
1. The conditional order execution fee (hereafter referred to as `co_fee`) is paid by the account identified by the `ConditionalOrder.accountId`
2. The `co_fee` is denominated in `snxUSD` (i.e. the Synthetix USD stablecoin)
3. The `co_fee` is a function of the fee (hereafter referred to as `snx_fee`) imposed by Synthetix v3 Perps Markets to commit orders 
4. The `co_fee` will be 50% of the `snx_fee` imposed by Synthetix v3 Perps Markets to commit orders up to a maximum `snxUSD` value of $50
5. The `co_fee` will be withdrawn from the account identified by the `ConditionalOrder.accountId`
> note, this is done prior to the order actually being commited to the Synthetix v3 Perps Market
6. The `co_fee` will transfered to the `msg.sender` calling the `Engine.execute` function
7. The `msg.sender` will be required to pay whatever gas in necessary to execute the `Engine.execute` function

#### What can go wrong?
1. If the `ConditionalOrder` meets all the conditions specified for execution, but the `ConditionalOrder.accountId` does not have enough `snxUSD` to pay the `co_fee`, then the `ConditionalOrder` will fail during execution
2. If the `ConditionalOrder` meets all the conditions specified for execution, but the `ConditionalOrder.accountId` does not have enough `collateral` to commit the order to the Synthetix v3 Perps Market, then the `ConditionalOrder` will fail during execution
3. The `Engine.canExecute` function can be called to check whether a `ConditionalOrder` can be executed prior to calling the `Engine.execute` function but **IT WILL NOT** check if the account identified by the `ConditionalOrder.accountId` has enough `snxUSD` to pay the `co_fee` nor will it check if the account identified by the `ConditionalOrder.accountId` has enough `collateral` to commit the order to the Synthetix v3 Perps Market
4. It is recommended that Kwenta warns users to always have a reasonable amount collateral denominated in `snxUSD` in their account when submitting a `ConditionalOrder` to avoid the `ConditionalOrder` failing during execution due to insufficient `snxUSD` to pay the `co_fee`

### Glossary
> @custom:todo add terms as you go and define any terms that are missing definitions
- Position Size (`size`): Measured in units of the base asset. Long positions have `size > 0`, while short positions have `size < 0`. for example a *short* position worth 10 ETH will have `size = -10`. 
> note that in an on-chain context, 10 ETH is represented as `10 * 10^18` (ETH has 18 decimals).
- Account Collateral (`collateral`): 
- Account Margin (`margin`):
- Settlement Strategy Id (`settlementStrategyId`):
- Acceptable Price (`acceptablePrice`):
- Referrer (`referrer`):

## Contracts
> to run: `tree src/`
```
src/
├── Engine.sol
├── interfaces
│   ├── IEngine.sol
│   ├── oracles
│   │   └── IPyth.sol
│   ├── synthetix
│   │   ├── IPerpsMarketProxy.sol
│   │   └── ISpotMarketProxy.sol
│   └── tokens
│       └── IERC20.sol
├── libraries
│   ├── ConditionalOrderHash.sol
│   ├── Int128Lib.sol
│   ├── Int256Lib.sol
│   └── SignatureCheckerLib.sol
└── utils
    ├── EIP712.sol
    ├── ERC721Receivable.sol
    ├── Multicallable.sol
    └── Ownable.sol
```

## Tests

1. Follow the [Foundry guide to working on an existing project](https://book.getfoundry.sh/projects/working-on-an-existing-project.html)

2. Build project

```
npm run compile
```

3. Execute both unit and integration tests (both run in forked environments)

```
npm run test
```

4. Run specific test

```
forge test --fork-url $(grep OPTIMISM_GOERLI_RPC_URL .env | cut -d '=' -f2) --match-test TEST_NAME -vvv
```

## Deployment Addresses
> See `deployments/` folder
1. Optimism deployments found in `deployments/Optimism/`
2. Optimism Goerli deployments found in `deployments/OptimismGoerli/`

## Audits
> See `audits/` folder
1. Internal audits found in `audits/internal/`
2. External audits found in `audits/external/`
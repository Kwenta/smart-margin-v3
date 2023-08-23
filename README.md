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
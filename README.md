# 🧱 Smart Margin v3

[![Github Actions][gha-badge]][gha] 
[![Foundry][foundry-badge]][foundry] 
[![License: MIT][license-badge]][license]

[gha]: https://github.com/Kwenta/smart-margin-v3/actions
[gha-badge]: https://github.com/Kwenta/smart-margin-v3/actions/workflows/test.yml/badge.svg
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[license]: https://opensource.org/licenses/MIT
[license-badge]: https://img.shields.io/badge/License-MIT-blue.svg

## Overview

## Contracts
> to run: `tree src/`
```
src/
├── MarginEngine.sol
├── interfaces
│   ├── IAuth.sol
│   ├── IMarginEngine.sol
│   ├── synthetix
│   │   ├── IPerpsMarketProxy.sol
│   │   └── ISpotMarketProxy.sol
│   └── tokens
│       └── IERC20.sol
├── libraries
│   ├── Int128Lib.sol
│   └── Int256Lib.sol
├── modules
│   ├── Auth.sol
│   ├── OrderBook.sol
│   └── Stats.sol
├── tokens
│   └── ERC721Receiver.sol
└── utils
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
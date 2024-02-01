# 🧱 Smart Margin v3

[![Github Actions][gha-badge]][gha]
[![Foundry][foundry-badge]][foundry]
[![License: GPL-3.0][license-badge]][license]

[gha]: https://github.com/Kwenta/smart-margin-v3/actions
[gha-badge]: https://github.com/Kwenta/smart-margin-v3/actions/workflows/test.yml/badge.svg
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[license]: https://opensource.org/license/GPL-3.0/
[license-badge]: https://img.shields.io/badge/GitHub-GPL--3.0-informational

## Docs

Please refer to the project [wiki](https://github.com/Kwenta/smart-margin-v3/wiki) for all documentation.

## Contracts

> `tree src/`

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

## Tests
1. Install dependencies

```
npm i
```

2. Follow the [Foundry guide to working on an existing project](https://book.getfoundry.sh/projects/working-on-an-existing-project.html)

3. Build project

```
npm run compile
```

4. Execute forge tests (requires rpc url(s) to be set in `.env`)

```
npm run test
```

5. Run specific forge test

```
forge test --fork-url $(grep BASE_RPC_URL .env | cut -d '=' -f2) --match-test TEST_NAME -vvv
```

6. Decode a custom error defined by Synthetix v3
    > ex: `npm run decode-custom-error -- 0x01de5522...`

```
npm run decode-custom-error -- <error hash 0x...>
```

7. Run hardhat tests
> project must be compiled first (see step 2)

```
npm run test:hh
```

## Deployment Addresses

> See `deployments/` folder

1. Optimism deployments found in `deployments/Optimism.json`
2. Optimism Goerli deployments found in `deployments/OptimismGoerli.json`
3. Base deployments found in `deployments/Base.json`
4. Base Goerli deployments found in `deployments/BaseGoerli.json`

## Audits

> See `audits/` folder

1. Internal audits found in `audits/internal/`
2. External audits found in `audits/external/`

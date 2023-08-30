# 🧱 Smart Margin v3

[![Github Actions][gha-badge]][gha]
[![Foundry][foundry-badge]][foundry]
[![License: MIT][license-badge]][license]

[gha]: https://github.com/Kwenta/smart-margin-v3/actions
[gha-badge]: https://github.com/Kwenta/smart-margin-v3/actions/workflows/test.yml/badge.svg
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[license]: https://opensource.org/license/GPL-3.0/
[license-badge]: https://img.shields.io/badge/GitHub-GPL--3.0-informational

## Contracts

> `tree src/`

```
src/
├── Engine.sol
├── interfaces
│   ├── IEngine.sol
│   ├── oracles
│   │   └── IPyth.sol
│   ├── synthetix
│   │   ├── IPerpsMarketProxy.sol
│   │   └── ISpotMarketProxy.sol
│   └── tokens
│       ├── IERC20.sol
│       └── IERC721.sol
├── libraries
│   ├── ConditionalOrderHashLib.sol
│   ├── MathLib.sol
│   └── SignatureCheckerLib.sol
└── utils
    ├── EIP712.sol
    ├── ERC721Receivable.sol
    └── Multicallable.sol
```

## Tests

1. Follow the [Foundry guide to working on an existing project](https://book.getfoundry.sh/projects/working-on-an-existing-project.html)

2. Build project

```
npm run compile
```

3. Execute tests (requires rpc url(s) to be set in `.env`)

```
npm run test
```

4. Run specific test
    > `OPTIMISM_GOERLI_RPC_URL` can be replaced with `OPTIMISM_RPC_URL` if a mainnet fork is desired

```
forge test --fork-url $(grep OPTIMISM_GOERLI_RPC_URL .env | cut -d '=' -f2) --match-test TEST_NAME -vvv
```

5. Decode a custom error defined by Synthetix v3
    > ex: `npm run decode-custom-error -- 0x01de5522...`

```
npm run decode-custom-error -- <error hash 0x...>
```

## Deployment Addresses

> See `deployments/` folder

1. Optimism deployments found in `deployments/Optimism/`
2. Optimism Goerli deployments found in `deployments/OptimismGoerli/`

## Audits

> See `audits/` folder

1. Internal audits found in `audits/internal/`
2. External audits found in `audits/external/`

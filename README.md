# foundry-scaffold

[![Github Actions][gha-badge]][gha] 
[![Foundry][foundry-badge]][foundry] 
[![License: MIT][license-badge]][license]

[gha]: https://github.com/Kwenta/foundry-scaffold/actions
[gha-badge]: https://github.com/Kwenta/foundry-scaffold/actions/workflows/test.yml/badge.svg
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[license]: https://opensource.org/licenses/MIT
[license-badge]: https://img.shields.io/badge/License-MIT-blue.svg

Template for a foundry project.

## Contracts

```
script/TestnetDeploy.s.sol ^0.8.13
└── lib/forge-std/src/Script.sol >=0.6.0 <0.9.0
    ├── lib/forge-std/src/console.sol >=0.4.22 <0.9.0
    ├── lib/forge-std/src/console2.sol >=0.4.22 <0.9.0
    └── lib/forge-std/src/StdJson.sol >=0.6.0 <0.9.0
        └── lib/forge-std/src/Vm.sol >=0.6.0 <0.9.0
src/Counter.sol ^0.8.13
test/Counter.t.sol ^0.8.13
├── lib/forge-std/src/Test.sol >=0.6.0 <0.9.0
│   ├── lib/forge-std/src/Script.sol >=0.6.0 <0.9.0 (*)
│   └── lib/forge-std/lib/ds-test/src/test.sol >=0.5.0
└── src/Counter.sol ^0.8.13
```

## Code Coverage

```
+----------------------------+---------------+---------------+---------------+---------------+
| File                       | % Lines       | % Statements  | % Branches    | % Funcs       |
+============================================================================================+
| script/TestnetDeploy.s.sol | 0.00% (0/3)   | 0.00% (0/4)   | 100.00% (0/0) | 0.00% (0/1)   |
|----------------------------+---------------+---------------+---------------+---------------|
| src/Counter.sol            | 100.00% (2/2) | 100.00% (2/2) | 100.00% (0/0) | 100.00% (2/2) |
|----------------------------+---------------+---------------+---------------+---------------|
| Total                      | 40.00% (2/5)  | 33.33% (2/6)  | 100.00% (0/0) | 66.67% (2/3)  |
+----------------------------+---------------+---------------+---------------+---------------+
```

## Deployment Addresses

#### Optimism

#### Optimism Goerli
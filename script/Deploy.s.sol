// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Engine} from "src/Engine.sol";
import {OptimismGoerliParameters} from
    "script/utils/parameters/OptimismGoerliParameters.sol";
import {OptimismParameters} from
    "script/utils/parameters/OptimismParameters.sol";
import {Script} from "lib/forge-std/src/Script.sol";

contract Setup is Script {
    function deploySystem(
        address perpsMarketProxy,
        address spotMarketProxy,
        address sUSDProxy,
        address oracle,
        bytes32 pythPriceFeedIdEthUsd
    ) public returns (Engine engine) {
        engine = new Engine({
            _perpsMarketProxy: perpsMarketProxy,
            _spotMarketProxy: spotMarketProxy,
            _sUSDProxy: sUSDProxy,
            _oracle: oracle,
            _pythPriceFeedIdEthUsd: pythPriceFeedIdEthUsd
        });
    }
}

/// @dev steps to deploy and verify on Optimism:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script script/Deploy.s.sol:DeployOptimism --rpc-url $OPTIMISM_RPC_URL --broadcast --verify -vvvv`
contract DeployOptimism is Setup, OptimismParameters {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Setup.deploySystem({
            perpsMarketProxy: PERPS_MARKET_PROXY,
            spotMarketProxy: SPOT_MARKET_PROXY,
            sUSDProxy: USD_PROXY,
            oracle: PYTH,
            pythPriceFeedIdEthUsd: PYTH_ETH_USD_ID
        });

        vm.stopBroadcast();
    }
}
/// @dev steps to deploy and verify on Optimism Goerli:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script script/Deploy.s.sol:DeployOptimismGoerli --rpc-url $OPTIMISM_GOERLI_RPC_URL --broadcast --verify -vvvv`
contract DeployOptimismGoerli is Setup, OptimismGoerliParameters {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Setup.deploySystem({
            perpsMarketProxy: PERPS_MARKET_PROXY,
            spotMarketProxy: SPOT_MARKET_PROXY,
            sUSDProxy: USD_PROXY,
            oracle: PYTH,
            pythPriceFeedIdEthUsd: PYTH_ETH_USD_ID
        });

        vm.stopBroadcast();
    }
}

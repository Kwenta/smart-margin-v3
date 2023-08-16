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
        address sUSDProxy
    ) public returns (Engine engine) {
        engine = new Engine({
            _perpsMarketProxy: perpsMarketProxy,
            _spotMarketProxy: spotMarketProxy,
            _sUSDProxy: sUSDProxy
        });
    }
}

contract DeployOptimism is Setup, OptimismParameters {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Setup.deploySystem({
            perpsMarketProxy: OPTIMISM_PERPS_MARKET_PROXY,
            spotMarketProxy: OPTIMISM_SPOT_MARKET_PROXY,
            sUSDProxy: OPTIMISM_USD_PROXY
        });

        vm.stopBroadcast();
    }
}

contract DeployOptimismGoerli is Setup, OptimismGoerliParameters {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Setup.deploySystem({
            perpsMarketProxy: OPTIMISM_GOERLI_PERPS_MARKET_PROXY,
            spotMarketProxy: OPTIMISM_GOERLI_SPOT_MARKET_PROXY,
            sUSDProxy: OPTIMISM_GOERLI_USD_PROXY
        });

        vm.stopBroadcast();
    }
}

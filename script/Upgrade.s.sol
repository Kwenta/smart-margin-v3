// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

// contracts
import {Engine} from "src/Engine.sol";

// parameters
import {BaseParameters} from "script/utils/parameters/BaseParameters.sol";
import {BaseSepoliaParameters} from
    "script/utils/parameters/BaseSepoliaParameters.sol";

// forge utils
import {Script} from "lib/forge-std/src/Script.sol";

/// @title Kwenta Smart Margin v3 upgrade script
/// @dev identical to Deploy script except no proxy is deployed
/// @author JaredBorders (jaredborders@pm.me)
contract Setup is Script {
    function deployImplementation(
        address perpsMarketProxy,
        address spotMarketProxy,
        address sUSDProxy,
        address pDAO,
        address zap,
        address usdc,
        address weth
    ) public returns (Engine engine) {
        engine = new Engine({
            _perpsMarketProxy: perpsMarketProxy,
            _spotMarketProxy: spotMarketProxy,
            _sUSDProxy: sUSDProxy,
            _pDAO: pDAO,
            _zap: zap,
            _usdc: usdc,
            _weth: weth
        });
    }
}

/// @dev steps to deploy and verify on Base:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script script/Upgrade.s.sol:DeployBase --rpc-url $BASE_RPC_URL --etherscan-api-key $BASESCAN_API_KEY --broadcast --verify -vvvv`
contract DeployBase is Setup, BaseParameters {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Setup.deployImplementation({
            perpsMarketProxy: PERPS_MARKET_PROXY_ANDROMEDA,
            spotMarketProxy: SPOT_MARKET_PROXY_ANDROMEDA,
            sUSDProxy: USD_PROXY_ANDROMEDA,
            pDAO: PDAO,
            zap: ZAP,
            usdc: USDC,
            weth: WETH
        });

        vm.stopBroadcast();
    }
}

/// @dev steps to deploy and verify on Base:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script script/Upgrade.s.sol:DeployBaseSepolia --rpc-url $BASE_SEPOLIA_RPC_URL --etherscan-api-key $BASESCAN_API_KEY --broadcast --verify -vvvv`
contract DeployBaseSepolia is Setup, BaseSepoliaParameters {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Setup.deployImplementation({
            perpsMarketProxy: PERPS_MARKET_PROXY_ANDROMEDA,
            spotMarketProxy: SPOT_MARKET_PROXY_ANDROMEDA,
            sUSDProxy: USD_PROXY_ANDROMEDA,
            pDAO: PDAO,
            zap: ZAP,
            usdc: USDC,
            weth: WETH
        });

        vm.stopBroadcast();
    }
}

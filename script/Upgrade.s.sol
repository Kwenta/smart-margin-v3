// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

// contracts
import {Engine} from "src/Engine.sol";

// parameters
import {ArbitrumParameters} from
    "script/utils/parameters/ArbitrumParameters.sol";
import {ArbitrumSepoliaParameters} from
    "script/utils/parameters/ArbitrumSepoliaParameters.sol";

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
/// (2) run `forge script script/Upgrade.s.sol:DeployArbitrum --rpc-url $ARBITRUM_RPC_URL --etherscan-api-key $ARBISCAN_API_KEY --broadcast --verify -vvvv`
contract DeployArbitrum is Setup, ArbitrumParameters {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Setup.deployImplementation({
            perpsMarketProxy: PERPS_MARKET_PROXY,
            spotMarketProxy: SPOT_MARKET_PROXY,
            sUSDProxy: USD_PROXY,
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
/// (2) run `forge script script/Upgrade.s.sol:DeployArbitrumSepolia --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --etherscan-api-key $ARBISCAN_API_KEY --broadcast --verify -vvvv`
contract DeployArbitrumSepolia is Setup, ArbitrumSepoliaParameters {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Setup.deployImplementation({
            perpsMarketProxy: PERPS_MARKET_PROXY,
            spotMarketProxy: SPOT_MARKET_PROXY,
            sUSDProxy: USD_PROXY,
            pDAO: PDAO,
            zap: ZAP,
            usdc: USDC,
            weth: WETH
        });

        vm.stopBroadcast();
    }
}

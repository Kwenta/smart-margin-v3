// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

// contracts
import {Engine} from "src/Engine.sol";

// parameters
import {BaseGoerliParameters} from
    "script/utils/parameters/BaseGoerliParameters.sol";
import {BaseParameters} from "script/utils/parameters/BaseParameters.sol";
import {OptimismGoerliParameters} from
    "script/utils/parameters/OptimismGoerliParameters.sol";
import {BaseSepoliaParameters} from
    "script/utils/parameters/BaseSepoliaParameters.sol";
import {BaseGoerliKwentaForkParameters} from
    "script/utils/parameters/BaseGoerliKwentaForkParameters.sol";
import {OptimismParameters} from
    "script/utils/parameters/OptimismParameters.sol";

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
        address usdc,
        uint128 sUSDCId
    ) public returns (Engine engine) {
        engine = new Engine({
            _perpsMarketProxy: perpsMarketProxy,
            _spotMarketProxy: spotMarketProxy,
            _sUSDProxy: sUSDProxy,
            _pDAO: pDAO,
            _usdc: usdc,
            _sUSDCId: sUSDCId
        });
    }
}

/// @dev steps to deploy and verify on Base:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script script/Upgrade.s.sol:DeployBase_Synthetix --rpc-url $BASE_RPC_URL --etherscan-api-key $BASESCAN_API_KEY --broadcast --verify -vvvv`
contract DeployBase_Synthetix is Setup, BaseParameters {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Setup.deployImplementation({
            perpsMarketProxy: PERPS_MARKET_PROXY,
            spotMarketProxy: SPOT_MARKET_PROXY,
            sUSDProxy: USD_PROXY,
            pDAO: PDAO,
            usdc: USDC,
            sUSDCId: SUSDC_SPOT_MARKET_ID
        });

        vm.stopBroadcast();
    }
}

/// @dev steps to deploy and verify on Base Goerli:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script script/Upgrade.s.sol:DeployBaseSepolia_Andromeda --rpc-url $BASE_SEPOLIA_RPC_URL --etherscan-api-key $BASESCAN_API_KEY --broadcast --verify -vvvv`
contract DeployBaseSepolia_Andromeda is Setup, BaseSepoliaParameters {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Setup.deployImplementation({
            perpsMarketProxy: PERPS_MARKET_PROXY_ANDROMEDA,
            spotMarketProxy: SPOT_MARKET_PROXY_ANDROMEDA,
            sUSDProxy: USD_PROXY_ANDROMEDA,
            pDAO: PDAO,
            usdc: USDC,
            sUSDCId: SUSDC_SPOT_MARKET_ID
        });

        vm.stopBroadcast();
    }
}


/// @dev steps to deploy and verify on Base Goerli:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script script/Upgrade.s.sol:DeployBaseGoerli_Synthetix --rpc-url $BASE_GOERLI_RPC_URL --etherscan-api-key $BASESCAN_API_KEY --broadcast --verify -vvvv`
contract DeployBaseGoerli_Synthetix is Setup, BaseGoerliParameters {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Setup.deployImplementation({
            perpsMarketProxy: PERPS_MARKET_PROXY,
            spotMarketProxy: SPOT_MARKET_PROXY,
            sUSDProxy: USD_PROXY,
            pDAO: PDAO,
            usdc: USDC,
            sUSDCId: SUSDC_SPOT_MARKET_ID
        });

        vm.stopBroadcast();
    }
}

/// @dev steps to deploy and verify on Base Goerli for the Kwenta Synthetix V3 Fork:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script script/Upgrade.s.sol:DeployBaseGoerli_KwentaFork --rpc-url $BASE_GOERLI_RPC_URL --etherscan-api-key $BASESCAN_API_KEY --broadcast --verify -vvvv`
contract DeployBaseGoerli_KwentaFork is
    Setup,
    BaseGoerliKwentaForkParameters
{
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Setup.deployImplementation({
            perpsMarketProxy: PERPS_MARKET_PROXY,
            spotMarketProxy: SPOT_MARKET_PROXY,
            sUSDProxy: USD_PROXY,
            pDAO: PDAO,
            usdc: USDC,
            sUSDCId: SUSDC_SPOT_MARKET_ID
        });

        vm.stopBroadcast();
    }
}

/// @dev steps to deploy and verify on Base Goerli:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script script/Upgrade.s.sol:DeployBaseGoerli_Andromeda --rpc-url $BASE_GOERLI_RPC_URL --etherscan-api-key $BASESCAN_API_KEY --broadcast --verify -vvvv`
contract DeployBaseGoerli_Andromeda is Setup, BaseGoerliParameters {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Setup.deployImplementation({
            perpsMarketProxy: PERPS_MARKET_PROXY_ANDROMEDA,
            spotMarketProxy: SPOT_MARKET_PROXY_ANDROMEDA,
            sUSDProxy: USD_PROXY_ANDROMEDA,
            pDAO: PDAO,
            usdc: USDC,
            sUSDCId: SUSDC_SPOT_MARKET_ID
        });

        vm.stopBroadcast();
    }
}

/// @dev steps to deploy and verify on Optimism:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script script/Upgrade.s.sol:DeployOptimism_Synthetix --rpc-url $OPTIMISM_RPC_URL --etherscan-api-key $OPTIMISM_ETHERSCAN_API_KEY --broadcast --verify -vvvv`
contract DeployOptimism_Synthetix is Setup, OptimismParameters {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Setup.deployImplementation({
            perpsMarketProxy: PERPS_MARKET_PROXY,
            spotMarketProxy: SPOT_MARKET_PROXY,
            sUSDProxy: USD_PROXY,
            pDAO: PDAO,
            usdc: USDC,
            sUSDCId: SUSDC_SPOT_MARKET_ID
        });

        vm.stopBroadcast();
    }
}

/// @dev steps to deploy and verify on Optimism Goerli:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script script/Upgrade.s.sol:DeployOptimismGoerli_Synthetix --rpc-url $OPTIMISM_GOERLI_RPC_URL --etherscan-api-key $OPTIMISM_ETHERSCAN_API_KEY --broadcast --verify -vvvv`
contract DeployOptimismGoerli_Synthetix is Setup, OptimismGoerliParameters {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Setup.deployImplementation({
            perpsMarketProxy: PERPS_MARKET_PROXY,
            spotMarketProxy: SPOT_MARKET_PROXY,
            sUSDProxy: USD_PROXY,
            pDAO: PDAO,
            usdc: USDC,
            sUSDCId: SUSDC_SPOT_MARKET_ID
        });

        vm.stopBroadcast();
    }
}

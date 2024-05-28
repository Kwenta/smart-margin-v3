// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

// contracts
import {Engine} from "src/Engine.sol";

// parameters
import {BaseSepoliaParameters} from
    "script/utils/parameters/BaseSepoliaParameters.sol";
import {BaseParameters} from "script/utils/parameters/BaseParameters.sol";

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
/// (2) run `forge script script/Upgrade.s.sol:DeployBase_Andromeda --rpc-url $BASE_RPC_URL --etherscan-api-key $BASESCAN_API_KEY --broadcast --verify -vvvv`
contract DeployBase_Andromeda is Setup, BaseParameters {
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

/// @dev steps to deploy and verify on Base:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script script/Upgrade.s.sol:DeployBaseSepolia_Andromeda --rpc-url $BASE_RPC_URL --etherscan-api-key $BASESCAN_API_KEY --broadcast --verify -vvvv`
contract DeployBaseSepolia_Andromeda is Setup, BaseSepoliaParameters {
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

// proxy
import {ERC1967Proxy as Proxy} from
    "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// contracts
import {Engine} from "src/Engine.sol";

// parameters
import {BaseParameters} from "script/utils/parameters/BaseParameters.sol";
import {BaseSepoliaParameters} from
    "script/utils/parameters/BaseSepoliaParameters.sol";

// forge utils
import {Script} from "lib/forge-std/src/Script.sol";

/// @title Kwenta Smart Margin v3 deployment script
/// @author JaredBorders (jaredborders@pm.me)
contract Setup is Script {
    function deploySystem(
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

        // deploy ERC1967 proxy and set implementation to engine
        Proxy proxy = new Proxy(address(engine), "");

        // "wrap" proxy in IEngine interface
        engine = Engine(address(proxy));
    }
}

/// @dev steps to deploy and verify on Base:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script script/Deploy.s.sol:DeployBase_Andromeda --rpc-url $BASE_RPC_URL --etherscan-api-key $BASESCAN_API_KEY --broadcast --verify -vvvv`
contract DeployBase_Andromeda is Setup, BaseParameters {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Setup.deploySystem({
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
/// (2) run `forge script script/Deploy.s.sol:DeployBaseSepolia_Andromeda --rpc-url $BASE_SEPOLIA_RPC_URL --etherscan-api-key $BASESCAN_API_KEY --broadcast --verify -vvvv`
contract DeployBaseSepolia_Andromeda is Setup, BaseSepoliaParameters {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Setup.deploySystem({
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

import {ERC1967Proxy as Proxy} from
    "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Engine} from "src/Engine.sol";
import {MulticallerWithSender} from "src/utils/MulticallerWithSender.sol";
import {BaseParameters} from "script/utils/parameters/BaseParameters.sol";
import {BaseSepoliaParameters} from
    "script/utils/parameters/BaseSepoliaParameters.sol";
import {Pay} from "src/utils/Pay.sol";

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
        address zap,
        address payable pay,
        address usdc,
        address weth
    ) public returns (Engine engine) {
        engine = new Engine({
            _perpsMarketProxy: perpsMarketProxy,
            _spotMarketProxy: spotMarketProxy,
            _sUSDProxy: sUSDProxy,
            _pDAO: pDAO,
            _zap: zap,
            _pay: pay,
            _usdc: usdc,
            _weth: weth
        });

        // deploy ERC1967 proxy and set implementation to engine
        Proxy proxy = new Proxy(address(engine), "");

        // "wrap" proxy in IEngine interface
        engine = Engine(payable(address(proxy)));
    }
}

/// @dev steps to deploy and verify on Base:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script script/Deploy.s.sol:DeployBase --rpc-url $BASE_RPC_URL --etherscan-api-key $BASESCAN_API_KEY --broadcast --verify -vvvv`
contract DeployBase is Setup, BaseParameters {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Setup.deploySystem({
            perpsMarketProxy: PERPS_MARKET_PROXY_ANDROMEDA,
            spotMarketProxy: SPOT_MARKET_PROXY_ANDROMEDA,
            sUSDProxy: USD_PROXY_ANDROMEDA,
            pDAO: PDAO,
            zap: ZAP,
            pay: PAY,
            usdc: USDC,
            weth: WETH
        });

        vm.stopBroadcast();
    }
}

/// @dev steps to deploy and verify on Base Sepolia:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script script/Deploy.s.sol:DeployBaseSepolia --rpc-url $BASE_SEPOLIA_RPC_URL --etherscan-api-key $BASESCAN_API_KEY --broadcast --verify -vvvv`
contract DeployBaseSepolia is Setup, BaseSepoliaParameters {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Setup.deploySystem({
            perpsMarketProxy: PERPS_MARKET_PROXY_ANDROMEDA,
            spotMarketProxy: SPOT_MARKET_PROXY_ANDROMEDA,
            sUSDProxy: USD_PROXY_ANDROMEDA,
            pDAO: PDAO,
            zap: ZAP,
            pay: PAY,
            usdc: USDC,
            weth: WETH
        });

        vm.stopBroadcast();
    }
}

/// @dev steps to deploy and verify on Base:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script script/Deploy.s.sol:DeployMulticallBase --rpc-url $BASE_RPC_URL --etherscan-api-key $BASESCAN_API_KEY --broadcast --verify -vvvv`
contract DeployMulticallBase is Setup, BaseParameters {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        new MulticallerWithSender();

        vm.stopBroadcast();
    }
}

/// @dev steps to deploy and verify on Base:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script script/Deploy.s.sol:DeployPay --rpc-url $BASE_RPC_URL --etherscan-api-key $BASESCAN_API_KEY --broadcast --verify -vvvv`
contract DeployPay is Setup, BaseParameters {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        new Pay(WETH);

        vm.stopBroadcast();
    }
}

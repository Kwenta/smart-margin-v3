// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {console2} from "lib/forge-std/src/console2.sol";
import {Test} from "lib/forge-std/src/Test.sol";
import {Conditions} from "test/utils/Conditions.sol";
import {Constants} from "test/utils/Constants.sol";
import {SynthetixV3Errors} from "test/utils/errors/SynthetixV3Errors.sol";
import {EngineExposed} from "test/utils/exposed/EngineExposed.sol";
import {
    Engine,
    OptimismGoerliParameters,
    OptimismParameters,
    Setup
} from "script/Deploy.s.sol";
import {IERC20} from "src/interfaces/tokens/IERC20.sol";
import {IPerpsMarketProxy} from "test/utils/interfaces/IPerpsMarketProxy.sol";
import {ISpotMarketProxy} from "src/interfaces/synthetix/ISpotMarketProxy.sol";
import {SynthMinter} from "test/utils/SynthMinter.sol";

/// @title Contract for bootstrapping the SMv3 system for testing purposes
/// @dev it deploys the SMv3 Engine and EngineExposed, and defines
/// the perpsMarketProxy, spotMarketProxy, sUSD, and sBTC contracts (notably)
/// @dev it deploys a SynthMinter contract for minting sUSD and sBTC
/// @dev it creates a Synthetix v3 perps market account for the "ACTOR" whose
/// address is defined in the Constants contract
/// @dev it mints "AMOUNT" of sUSD to the ACTOR for testing purposes
/// @dev it gives the Engine contract ADMIN_PERMISSION over the account owned by the ACTOR
/// which is defined by its accountId
///
/// @custom:network it can deploy the SMv3 system to the 
/// Optimism Goerli or Optimism network in a forked environment (relies on up-to-date constants)
///
/// @custom:deployment it uses the deploy script in the script/ directory to deploy the SMv3 system
/// and effectively tests the deploy script as well
///
/// @author JaredBorders (jaredborders@pm.me)
contract Bootstrap is Test, Constants, Conditions, SynthetixV3Errors {
    // lets any test contract that inherits from this contract 
    // use the console.log()
    using console2 for *;

    // deployed contracts
    Engine public engine;
    EngineExposed public engineExposed;
    SynthMinter public synthMinter;

    // defined contracts
    IPerpsMarketProxy public perpsMarketProxy;
    ISpotMarketProxy public spotMarketProxy;
    IERC20 public sUSD;
    IERC20 public sBTC;

    // ACTOR's account id in the Synthetix v3 perps market
    uint128 public accountId;

    function initializeOptimismGoerli() public {
        BootstrapOptimismGoerli bootstrap = new BootstrapOptimismGoerli();
        (
            address _engineAddress,
            address _engineExposedAddress,
            address _perpesMarketProxyAddress,
            address _spotMarketProxyAddress,
            address _sUSDAddress
        ) = bootstrap.init();

        engine = Engine(_engineAddress);
        engineExposed = EngineExposed(_engineExposedAddress);
        perpsMarketProxy = IPerpsMarketProxy(_perpesMarketProxyAddress);
        spotMarketProxy = ISpotMarketProxy(_spotMarketProxyAddress);
        sUSD = IERC20(_sUSDAddress);
        synthMinter = new SynthMinter(_sUSDAddress, _spotMarketProxyAddress);
        sBTC = synthMinter.sBTC();

        vm.startPrank(ACTOR);
        accountId = perpsMarketProxy.createAccount();
        perpsMarketProxy.grantPermission({
            accountId: accountId,
            permission: ADMIN_PERMISSION,
            user: address(engine)
        });
        vm.stopPrank();

        synthMinter.mint_sUSD(ACTOR, AMOUNT);
    }

    function initializeOptimism() public {
        BootstrapOptimismGoerli bootstrap = new BootstrapOptimismGoerli();
        (
            address _engineAddress,
            address _engineExposedAddress,
            address _perpesMarketProxyAddress,
            address _spotMarketProxyAddress,
            address _sUSDAddress
        ) = bootstrap.init();

        engine = Engine(_engineAddress);
        engineExposed = EngineExposed(_engineExposedAddress);
        perpsMarketProxy = IPerpsMarketProxy(_perpesMarketProxyAddress);
        spotMarketProxy = ISpotMarketProxy(_spotMarketProxyAddress);
        sUSD = IERC20(_sUSDAddress);
        synthMinter = new SynthMinter(_sUSDAddress, _spotMarketProxyAddress);
        sBTC = synthMinter.sBTC();

        vm.startPrank(ACTOR);
        accountId = perpsMarketProxy.createAccount();
        perpsMarketProxy.grantPermission({
            accountId: accountId,
            permission: ADMIN_PERMISSION,
            user: address(engine)
        });
        vm.stopPrank();

        synthMinter.mint_sUSD(ACTOR, AMOUNT);
    }
}

contract BootstrapOptimism is Setup, OptimismParameters {
    function init()
        public
        returns (address, address, address, address, address)
    {
        (Engine engine) = Setup.deploySystem({
            perpsMarketProxy: PERPS_MARKET_PROXY,
            spotMarketProxy: SPOT_MARKET_PROXY,
            sUSDProxy: USD_PROXY
        });

        EngineExposed engineExposed = new EngineExposed({
            _perpsMarketProxy: PERPS_MARKET_PROXY,
            _spotMarketProxy: SPOT_MARKET_PROXY,
            _sUSDProxy: USD_PROXY
        });

        return (
            address(engine),
            address(engineExposed),
            PERPS_MARKET_PROXY,
            SPOT_MARKET_PROXY,
            USD_PROXY
        );
    }
}

contract BootstrapOptimismGoerli is Setup, OptimismGoerliParameters {
    function init()
        public
        returns (address, address, address, address, address)
    {
        (Engine engine) = Setup.deploySystem({
            perpsMarketProxy: PERPS_MARKET_PROXY,
            spotMarketProxy: SPOT_MARKET_PROXY,
            sUSDProxy: USD_PROXY
        });

        EngineExposed engineExposed = new EngineExposed({
            _perpsMarketProxy: PERPS_MARKET_PROXY,
            _spotMarketProxy: SPOT_MARKET_PROXY,
            _sUSDProxy: USD_PROXY
        });

        return (
            address(engine),
            address(engineExposed),
            PERPS_MARKET_PROXY,
            SPOT_MARKET_PROXY,
            USD_PROXY
        );
    }
}

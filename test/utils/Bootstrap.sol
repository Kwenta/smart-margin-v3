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
    BaseParameters,
    BaseGoerliParameters,
    Setup
} from "script/Deploy.s.sol";
import {IERC20} from "src/interfaces/tokens/IERC20.sol";
import {IPerpsMarketProxy} from "test/utils/interfaces/IPerpsMarketProxy.sol";
import {ISpotMarketProxy} from "src/interfaces/synthetix/ISpotMarketProxy.sol";
import {SynthMinter} from "test/utils/SynthMinter.sol";

/// @title Contract for bootstrapping the SMv3 system for testing purposes
/// @dev it deploys the SMv3 Engine and EngineExposed, and defines
/// the perpsMarketProxy, spotMarketProxy, sUSD, and USDC contracts (notably)
/// @dev it deploys a SynthMinter contract for minting sUSD
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

    // pDAO address
    address public pDAO;

    // deployed contracts
    Engine public engine;
    EngineExposed public engineExposed;
    SynthMinter public synthMinter;

    // defined contracts
    IPerpsMarketProxy public perpsMarketProxy;
    ISpotMarketProxy public spotMarketProxy;
    IERC20 public sUSD;
    IERC20 public USDC;

    // Synthetix v3 Andromeda Spot Market ID for $sUSDC
    uint128 public sUSDCId;

    // ACTOR's account id in the Synthetix v3 perps market
    uint128 public accountId;

    function initializeOptimism() public {
        BootstrapOptimismGoerli bootstrap = new BootstrapOptimismGoerli();
        (
            address _engineAddress,
            address _engineExposedAddress,
            address _perpsMarketProxyAddress,
            address _spotMarketProxyAddress,
            address _sUSDAddress,
            address _pDAOAddress,
            address _usdc,
            uint128 _sUSDCId
        ) = bootstrap.init();

        engine = Engine(_engineAddress);
        engineExposed = EngineExposed(_engineExposedAddress);
        perpsMarketProxy = IPerpsMarketProxy(_perpsMarketProxyAddress);
        spotMarketProxy = ISpotMarketProxy(_spotMarketProxyAddress);
        sUSD = IERC20(_sUSDAddress);
        synthMinter = new SynthMinter(_sUSDAddress, _spotMarketProxyAddress);
        pDAO = _pDAOAddress;
        USDC = IERC20(_usdc);
        sUSDCId = _sUSDCId;

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

    function initializeOptimismGoerli() public {
        BootstrapOptimismGoerli bootstrap = new BootstrapOptimismGoerli();
        (
            address _engineAddress,
            address _engineExposedAddress,
            address _perpsMarketProxyAddress,
            address _spotMarketProxyAddress,
            address _sUSDAddress,
            address _pDAOAddress,
            address _usdc,
            uint128 _sUSDCId
        ) = bootstrap.init();

        engine = Engine(_engineAddress);
        engineExposed = EngineExposed(_engineExposedAddress);
        perpsMarketProxy = IPerpsMarketProxy(_perpsMarketProxyAddress);
        spotMarketProxy = ISpotMarketProxy(_spotMarketProxyAddress);
        sUSD = IERC20(_sUSDAddress);
        synthMinter = new SynthMinter(_sUSDAddress, _spotMarketProxyAddress);
        pDAO = _pDAOAddress;
        USDC = IERC20(_usdc);
        sUSDCId = _sUSDCId;

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

    function initializeBase() public {
        BootstrapBase bootstrap = new BootstrapBase();
        (
            address _engineAddress,
            address _engineExposedAddress,
            address _perpsMarketProxyAddress,
            address _spotMarketProxyAddress,
            address _sUSDAddress,
            address _pDAOAddress,
            address _usdc,
            uint128 _sUSDCId
        ) = bootstrap.init();

        engine = Engine(_engineAddress);
        engineExposed = EngineExposed(_engineExposedAddress);
        perpsMarketProxy = IPerpsMarketProxy(_perpsMarketProxyAddress);
        spotMarketProxy = ISpotMarketProxy(_spotMarketProxyAddress);
        sUSD = IERC20(_sUSDAddress);
        synthMinter = new SynthMinter(_sUSDAddress, _spotMarketProxyAddress);
        pDAO = _pDAOAddress;
        USDC = IERC20(_usdc);
        sUSDCId = _sUSDCId;

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

    function initializeBaseGoerli() public {
        BootstrapBaseGoerli bootstrap = new BootstrapBaseGoerli();
        (
            address _engineAddress,
            address _engineExposedAddress,
            address _perpsMarketProxyAddress,
            address _spotMarketProxyAddress,
            address _sUSDAddress,
            address _pDAOAddress,
            address _usdc,
            uint128 _sUSDCId
        ) = bootstrap.init();

        engine = Engine(_engineAddress);
        engineExposed = EngineExposed(_engineExposedAddress);
        perpsMarketProxy = IPerpsMarketProxy(_perpsMarketProxyAddress);
        spotMarketProxy = ISpotMarketProxy(_spotMarketProxyAddress);
        sUSD = IERC20(_sUSDAddress);
        synthMinter = new SynthMinter(_sUSDAddress, _spotMarketProxyAddress);
        pDAO = _pDAOAddress;
        USDC = IERC20(_usdc);
        sUSDCId = _sUSDCId;

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
        returns (
            address,
            address,
            address,
            address,
            address,
            address,
            address,
            uint128
        )
    {
        (Engine engine) = Setup.deploySystem({
            perpsMarketProxy: PERPS_MARKET_PROXY,
            spotMarketProxy: SPOT_MARKET_PROXY,
            sUSDProxy: USD_PROXY,
            pDAO: PDAO,
            usdc: USDC,
            sUSDCId: SUSDC_SPOT_MARKET_ID
        });

        EngineExposed engineExposed = new EngineExposed({
            _perpsMarketProxy: PERPS_MARKET_PROXY,
            _spotMarketProxy: SPOT_MARKET_PROXY,
            _sUSDProxy: USD_PROXY,
            _pDAO: PDAO,
            _usdc: USDC,
            _sUSDCId: SUSDC_SPOT_MARKET_ID
        });

        return (
            address(engine),
            address(engineExposed),
            PERPS_MARKET_PROXY,
            SPOT_MARKET_PROXY,
            USD_PROXY,
            PDAO,
            USDC,
            SUSDC_SPOT_MARKET_ID
        );
    }
}

contract BootstrapOptimismGoerli is Setup, OptimismGoerliParameters {
    function init()
        public
        returns (
            address,
            address,
            address,
            address,
            address,
            address,
            address,
            uint128
        )
    {
        (Engine engine) = Setup.deploySystem({
            perpsMarketProxy: PERPS_MARKET_PROXY,
            spotMarketProxy: SPOT_MARKET_PROXY,
            sUSDProxy: USD_PROXY,
            pDAO: PDAO,
            usdc: USDC,
            sUSDCId: SUSDC_SPOT_MARKET_ID
        });

        EngineExposed engineExposed = new EngineExposed({
            _perpsMarketProxy: PERPS_MARKET_PROXY,
            _spotMarketProxy: SPOT_MARKET_PROXY,
            _sUSDProxy: USD_PROXY,
            _pDAO: PDAO,
            _usdc: USDC,
            _sUSDCId: SUSDC_SPOT_MARKET_ID
        });

        return (
            address(engine),
            address(engineExposed),
            PERPS_MARKET_PROXY,
            SPOT_MARKET_PROXY,
            USD_PROXY,
            PDAO,
            USDC,
            SUSDC_SPOT_MARKET_ID
        );
    }
}

contract BootstrapBase is Setup, BaseParameters {
    function init()
        public
        returns (
            address,
            address,
            address,
            address,
            address,
            address,
            address,
            uint128
        )
    {
        (Engine engine) = Setup.deploySystem({
            perpsMarketProxy: PERPS_MARKET_PROXY_ANDROMEDA,
            spotMarketProxy: SPOT_MARKET_PROXY_ANDROMEDA,
            sUSDProxy: USD_PROXY_ANDROMEDA,
            pDAO: PDAO,
            usdc: USDC,
            sUSDCId: SUSDC_SPOT_MARKET_ID
        });

        EngineExposed engineExposed = new EngineExposed({
            _perpsMarketProxy: PERPS_MARKET_PROXY_ANDROMEDA,
            _spotMarketProxy: SPOT_MARKET_PROXY_ANDROMEDA,
            _sUSDProxy: USD_PROXY_ANDROMEDA,
            _pDAO: PDAO,
            _usdc: USDC,
            _sUSDCId: SUSDC_SPOT_MARKET_ID
        });

        return (
            address(engine),
            address(engineExposed),
            PERPS_MARKET_PROXY_ANDROMEDA,
            SPOT_MARKET_PROXY_ANDROMEDA,
            USD_PROXY_ANDROMEDA,
            PDAO,
            USDC,
            SUSDC_SPOT_MARKET_ID
        );
    }
}

contract BootstrapBaseGoerli is Setup, BaseGoerliParameters {
    function init()
        public
        returns (
            address,
            address,
            address,
            address,
            address,
            address,
            address,
            uint128
        )
    {
        (Engine engine) = Setup.deploySystem({
            perpsMarketProxy: PERPS_MARKET_PROXY_ANDROMEDA,
            spotMarketProxy: SPOT_MARKET_PROXY_ANDROMEDA,
            sUSDProxy: USD_PROXY_ANDROMEDA,
            pDAO: PDAO,
            usdc: USDC,
            sUSDCId: SUSDC_SPOT_MARKET_ID
        });

        EngineExposed engineExposed = new EngineExposed({
            _perpsMarketProxy: PERPS_MARKET_PROXY_ANDROMEDA,
            _spotMarketProxy: SPOT_MARKET_PROXY_ANDROMEDA,
            _sUSDProxy: USD_PROXY_ANDROMEDA,
            _pDAO: PDAO,
            _usdc: USDC,
            _sUSDCId: SUSDC_SPOT_MARKET_ID
        });

        return (
            address(engine),
            address(engineExposed),
            PERPS_MARKET_PROXY_ANDROMEDA,
            SPOT_MARKET_PROXY_ANDROMEDA,
            USD_PROXY_ANDROMEDA,
            PDAO,
            USDC,
            SUSDC_SPOT_MARKET_ID
        );
    }
}

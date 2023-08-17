// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Conditions} from "test/utils/Conditions.sol";
import {Constants} from "test/utils/Constants.sol";
import {EngineExposed} from "test/utils/exposed/EngineExposed.sol";
import {
    Engine,
    OptimismGoerliParameters,
    OptimismParameters,
    Setup
} from "script/Deploy.s.sol";
import {IERC20} from "src/interfaces/tokens/IERC20.sol";
import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";
import {ISpotMarketProxy} from "src/interfaces/synthetix/ISpotMarketProxy.sol";
import {IPyth} from "src/interfaces/oracles/IPyth.sol";
import {SUSDHelper} from "test/utils/SUSDHelper.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract Bootstrap is Test, Constants, Conditions {
    Engine public engine;
    EngineExposed public engineExposed;
    IPerpsMarketProxy public perpsMarketProxy;
    ISpotMarketProxy public spotMarketProxy;
    IERC20 public sUSD;
    IPyth public pyth;
    bytes32 public pythPriceFeedIdEthUsd;

    SUSDHelper public sUSDHelper;
    uint128 public accountId;

    function initializeOptimismGoerli() public {
        BootstrapOptimismGoerli bootstrap = new BootstrapOptimismGoerli();
        (
            address _engineAddress,
            address _engineExposedAddress,
            address _perpesMarketProxyAddress,
            address _spotMarketProxyAddress,
            address _sUSDAddress,
            address _pythAddress,
            bytes32 _pythPriceFeedIdEthUsd
        ) = bootstrap.init();

        engine = Engine(_engineAddress);
        engineExposed = EngineExposed(_engineExposedAddress);
        perpsMarketProxy = IPerpsMarketProxy(_perpesMarketProxyAddress);
        spotMarketProxy = ISpotMarketProxy(_spotMarketProxyAddress);
        sUSD = IERC20(_sUSDAddress);
        pyth = IPyth(_pythAddress);
        pythPriceFeedIdEthUsd = _pythPriceFeedIdEthUsd;
        sUSDHelper = new SUSDHelper(_sUSDAddress);

        vm.startPrank(ACTOR);
        accountId = perpsMarketProxy.createAccount();
        perpsMarketProxy.grantPermission({
            accountId: accountId,
            permission: "ADMIN",
            user: address(engine)
        });
        vm.stopPrank();

        sUSDHelper.mint(ACTOR, AMOUNT);
    }

    function initializeOptimism() public {
        BootstrapOptimismGoerli bootstrap = new BootstrapOptimismGoerli();
        (
            address _engineAddress,
            address _engineExposedAddress,
            address _perpesMarketProxyAddress,
            address _spotMarketProxyAddress,
            address _sUSDAddress,
            address _pythAddress,
            bytes32 _pythPriceFeedIdEthUsd
        ) = bootstrap.init();

        engine = Engine(_engineAddress);
        engineExposed = EngineExposed(_engineExposedAddress);
        perpsMarketProxy = IPerpsMarketProxy(_perpesMarketProxyAddress);
        spotMarketProxy = ISpotMarketProxy(_spotMarketProxyAddress);
        sUSD = IERC20(_sUSDAddress);
        pyth = IPyth(_pythAddress);
        pythPriceFeedIdEthUsd = _pythPriceFeedIdEthUsd;
        sUSDHelper = new SUSDHelper(_sUSDAddress);

        vm.startPrank(ACTOR);
        accountId = perpsMarketProxy.createAccount();
        perpsMarketProxy.grantPermission({
            accountId: accountId,
            permission: "ADMIN",
            user: address(engine)
        });
        vm.stopPrank();

        sUSDHelper.mint(ACTOR, AMOUNT);
    }
}

contract BootstrapOptimism is Setup, OptimismParameters {
    function init()
        public
        returns (address, address, address, address, address, address, bytes32)
    {
        Engine engine = Setup.deploySystem({
            perpsMarketProxy: PERPS_MARKET_PROXY,
            spotMarketProxy: SPOT_MARKET_PROXY,
            sUSDProxy: USD_PROXY,
            oracle: PYTH,
            pythPriceFeedIdEthUsd: PYTH_ETH_USD_ID
        });

        EngineExposed engineExposed = new EngineExposed({
            _perpsMarketProxy: PERPS_MARKET_PROXY,
            _spotMarketProxy: SPOT_MARKET_PROXY,
            _sUSDProxy: USD_PROXY,
            _oracle: PYTH,
            _pythPriceFeedIdEthUsd: PYTH_ETH_USD_ID
        });

        return (
            address(engine),
            address(engineExposed),
            PERPS_MARKET_PROXY,
            SPOT_MARKET_PROXY,
            USD_PROXY,
            PYTH,
            PYTH_ETH_USD_ID
        );
    }
}

contract BootstrapOptimismGoerli is Setup, OptimismGoerliParameters {
    function init()
        public
        returns (address, address, address, address, address, address, bytes32)
    {
        Engine engine = Setup.deploySystem({
            perpsMarketProxy: PERPS_MARKET_PROXY,
            spotMarketProxy: SPOT_MARKET_PROXY,
            sUSDProxy: USD_PROXY,
            oracle: PYTH,
            pythPriceFeedIdEthUsd: PYTH_ETH_USD_ID
        });

        EngineExposed engineExposed = new EngineExposed({
            _perpsMarketProxy: PERPS_MARKET_PROXY,
            _spotMarketProxy: SPOT_MARKET_PROXY,
            _sUSDProxy: USD_PROXY,
            _oracle: PYTH,
            _pythPriceFeedIdEthUsd: PYTH_ETH_USD_ID
        });

        return (
            address(engine),
            address(engineExposed),
            PERPS_MARKET_PROXY,
            SPOT_MARKET_PROXY,
            USD_PROXY,
            PYTH,
            PYTH_ETH_USD_ID
        );
    }
}

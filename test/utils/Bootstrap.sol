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
import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";
import {ISpotMarketProxy} from "src/interfaces/synthetix/ISpotMarketProxy.sol";
import {IPyth} from "src/interfaces/oracles/IPyth.sol";
import {SynthetixMarketLookup} from "test/utils/SynthetixMarketLookup.sol";
import {SynthMinter} from "test/utils/SynthMinter.sol";
import {TrustedMulticallForwarder} from
    "lib/trusted-multicall-forwarder/src/TrustedMulticallForwarder.sol";

contract Bootstrap is Test, Constants, Conditions, SynthetixV3Errors {
    using console2 for *;

    Engine public engine;
    EngineExposed public engineExposed;
    TrustedMulticallForwarder public trustedForwarderContract;
    IPerpsMarketProxy public perpsMarketProxy;
    ISpotMarketProxy public spotMarketProxy;
    IERC20 public sUSD;
    IERC20 public USDC;
    IPyth public pyth;

    // spot market id's
    uint128 public sETHSpotMarketId;

    // perps market id's
    uint128 public sETHPerpsMarketId;

    SynthMinter public synthMinter;
    uint128 public accountId;

    receive() external payable {}

    function initializeOptimismGoerli() public {
        BootstrapOptimismGoerli bootstrap = new BootstrapOptimismGoerli();
        (
            address _engineAddress,
            address _engineExposedAddress,
            address _perpesMarketProxyAddress,
            address _spotMarketProxyAddress,
            address _sUSDAddress,
            address _pythAddress,
            address _trustedForwarderAddress,
            address _usdcAddress
        ) = bootstrap.init();

        engine = Engine(_engineAddress);
        engineExposed = EngineExposed(_engineExposedAddress);
        trustedForwarderContract =
            TrustedMulticallForwarder(_trustedForwarderAddress);
        perpsMarketProxy = IPerpsMarketProxy(_perpesMarketProxyAddress);
        spotMarketProxy = ISpotMarketProxy(_spotMarketProxyAddress);
        sUSD = IERC20(_sUSDAddress);
        pyth = IPyth(_pythAddress);
        synthMinter = new SynthMinter(_sUSDAddress, _spotMarketProxyAddress);
        USDC = IERC20(_usdcAddress);

        vm.startPrank(ACTOR);
        accountId = perpsMarketProxy.createAccount();
        perpsMarketProxy.grantPermission({
            accountId: accountId,
            permission: ADMIN_PERMISSION,
            user: address(engine)
        });
        vm.stopPrank();

        synthMinter.mint_sUSD(ACTOR, AMOUNT);

        SynthetixMarketLookup marketLookup = new SynthetixMarketLookup();
        sETHSpotMarketId = marketLookup.findSpotMarketId(
            "sETH Spot Market", address(spotMarketProxy)
        );
        sETHPerpsMarketId = marketLookup.findPerpsMarketId(
            "SETH Perps Market", address(perpsMarketProxy)
        );

        /// @custom:todo mint USDC?
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
            address _trustedForwarderAddress,
            address _usdcAddress
        ) = bootstrap.init();

        engine = Engine(_engineAddress);
        engineExposed = EngineExposed(_engineExposedAddress);
        trustedForwarderContract =
            TrustedMulticallForwarder(_trustedForwarderAddress);
        perpsMarketProxy = IPerpsMarketProxy(_perpesMarketProxyAddress);
        spotMarketProxy = ISpotMarketProxy(_spotMarketProxyAddress);
        sUSD = IERC20(_sUSDAddress);
        pyth = IPyth(_pythAddress);
        synthMinter = new SynthMinter(_sUSDAddress, _spotMarketProxyAddress);
        USDC = IERC20(_usdcAddress);

        vm.startPrank(ACTOR);
        accountId = perpsMarketProxy.createAccount();
        perpsMarketProxy.grantPermission({
            accountId: accountId,
            permission: ADMIN_PERMISSION,
            user: address(engine)
        });
        vm.stopPrank();

        synthMinter.mint_sUSD(ACTOR, AMOUNT);

        /// @custom:todo mint USDC?
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
            address
        )
    {
        (Engine engine, TrustedMulticallForwarder trustedForwarderContract) =
        Setup.deploySystem({
            perpsMarketProxy: PERPS_MARKET_PROXY,
            spotMarketProxy: SPOT_MARKET_PROXY,
            sUSDProxy: USD_PROXY,
            oracle: PYTH,
            usdc: USDC
        });

        EngineExposed engineExposed = new EngineExposed({
            _perpsMarketProxy: PERPS_MARKET_PROXY,
            _spotMarketProxy: SPOT_MARKET_PROXY,
            _sUSDProxy: USD_PROXY,
            _oracle: PYTH,
            _trustedForwarder: address(0x1),
            _usdc: USDC
        });

        return (
            address(engine),
            address(engineExposed),
            PERPS_MARKET_PROXY,
            SPOT_MARKET_PROXY,
            USD_PROXY,
            PYTH,
            address(trustedForwarderContract),
            USDC
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
            address
        )
    {
        (Engine engine, TrustedMulticallForwarder trustedForwarderContract) =
        Setup.deploySystem({
            perpsMarketProxy: PERPS_MARKET_PROXY,
            spotMarketProxy: SPOT_MARKET_PROXY,
            sUSDProxy: USD_PROXY,
            oracle: PYTH,
            usdc: USDC
        });

        EngineExposed engineExposed = new EngineExposed({
            _perpsMarketProxy: PERPS_MARKET_PROXY,
            _spotMarketProxy: SPOT_MARKET_PROXY,
            _sUSDProxy: USD_PROXY,
            _oracle: PYTH,
            _trustedForwarder: address(0x1),
            _usdc: USDC
        });

        return (
            address(engine),
            address(engineExposed),
            PERPS_MARKET_PROXY,
            SPOT_MARKET_PROXY,
            USD_PROXY,
            PYTH,
            address(trustedForwarderContract),
            USDC
        );
    }
}

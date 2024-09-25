// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {Engine, Setup} from "script/Deploy.s.sol";
import {IEngine} from "src/interfaces/IEngine.sol";
import {IERC20} from "src/utils/zap/interfaces/IERC20.sol";
import {ISpotMarket} from "src/utils/zap/interfaces/ISynthetix.sol";
import {Errors} from "src/utils/zap/Errors.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract DeploymentTest is Test, Setup {
    Setup setup;

    address internal perpsMarketProxy = address(0x1);
    address internal spotMarketProxy = address(0x2);
    address internal sUSDProxy = address(0x3);
    address internal pDAO = address(0x4);
    address internal usdc = address(0x5);
    uint128 internal sUSDCId = 1;
    address internal sUSDC = address(0x6);
    address internal zap = address(0x7);

    /// keccak256(abi.encodePacked("Synthetic USD Coin Spot Market"))
    bytes32 internal constant _HASHED_SUSDC_NAME =
        0xdb59c31a60f6ecfcb2e666ed077a3791b5c753b5a5e8dc5120f29367b94bbb22;

    function setUp() public {
        setup = new Setup();

        // mock call to $USDC contract that occurs in Zap constructor
        vm.mockCall(
            usdc,
            abi.encodeWithSelector(IERC20.decimals.selector),
            abi.encode(8)
        );

        // mock calls to Synthetix v3 Spot Market Proxy that occurs in Zap constructor
        vm.mockCall(
            spotMarketProxy,
            abi.encodeWithSelector(ISpotMarket.name.selector, sUSDCId),
            abi.encode(abi.encodePacked("Synthetic USD Coin Spot Market"))
        );
        vm.mockCall(
            spotMarketProxy,
            abi.encodeWithSelector(ISpotMarket.getSynth.selector, sUSDCId),
            abi.encode(sUSDC)
        );
    }

    function test_deploy() public {
        (Engine engine) = setup.deploySystem({
            perpsMarketProxy: perpsMarketProxy,
            spotMarketProxy: spotMarketProxy,
            sUSDProxy: sUSDProxy,
            pDAO: pDAO,
            zap: zap,
            usdc: usdc
        });

        assertTrue(address(engine) != address(0x0));
    }

    function test_deploy_perps_market_proxy_zero_address() public {
        try setup.deploySystem({
            perpsMarketProxy: address(0),
            spotMarketProxy: spotMarketProxy,
            sUSDProxy: sUSDProxy,
            pDAO: pDAO,
            zap: zap,
            usdc: usdc
        }) {} catch (bytes memory reason) {
            assertEq(bytes4(reason), IEngine.ZeroAddress.selector);
        }
    }

    function test_deploy_spot_market_proxy_zero_address() public {
        try setup.deploySystem({
            perpsMarketProxy: perpsMarketProxy,
            spotMarketProxy: address(0),
            sUSDProxy: sUSDProxy,
            pDAO: pDAO,
            zap: zap,
            usdc: usdc
        }) {} catch (bytes memory reason) {
            assertEq(bytes4(reason), IEngine.ZeroAddress.selector);
        }
    }

    function test_deploy_susd_proxy_zero_address() public {
        try setup.deploySystem({
            perpsMarketProxy: perpsMarketProxy,
            spotMarketProxy: spotMarketProxy,
            sUSDProxy: address(0),
            pDAO: pDAO,
            zap: zap,
            usdc: usdc
        }) {} catch (bytes memory reason) {
            assertEq(bytes4(reason), IEngine.ZeroAddress.selector);
        }
    }
}

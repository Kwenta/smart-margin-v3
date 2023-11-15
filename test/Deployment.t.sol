// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {Engine, Setup} from "script/Deploy.s.sol";
import {IEngine} from "src/interfaces/IEngine.sol";
import {Test} from "lib/forge-std/src/Test.sol";
import {TrustedMulticallForwarder} from
    "lib/trusted-multicall-forwarder/src/TrustedMulticallForwarder.sol";

contract DeploymentTest is Test, Setup {
    Setup setup;

    function setUp() public {
        setup = new Setup();
    }

    function test_deploy() public {
        (Engine engine, TrustedMulticallForwarder forwarder) = setup
            .deploySystem({
            perpsMarketProxy: address(0x1),
            spotMarketProxy: address(0x2),
            sUSDProxy: address(0x3),
            oracle: address(0x4),
            usdc: address(0x5)
        });

        assertTrue(address(engine) != address(0x0));
        assertTrue(address(forwarder) != address(0x0));
    }

    function test_deploy_perps_market_proxy_zero_address() public {
        try setup.deploySystem({
            perpsMarketProxy: address(0),
            spotMarketProxy: address(0x2),
            sUSDProxy: address(0x3),
            oracle: address(0x4),
            usdc: address(0x5)
        }) {} catch (bytes memory reason) {
            assertEq(bytes4(reason), IEngine.ZeroAddress.selector);
        }
    }

    function test_deploy_spot_market_proxy_zero_address() public {
        try setup.deploySystem({
            perpsMarketProxy: address(0x1),
            spotMarketProxy: address(0),
            sUSDProxy: address(0x3),
            oracle: address(0x4),
            usdc: address(0x5)
        }) {} catch (bytes memory reason) {
            assertEq(bytes4(reason), IEngine.ZeroAddress.selector);
        }
    }

    function test_deploy_susd_proxy_zero_address() public {
        try setup.deploySystem({
            perpsMarketProxy: address(0x1),
            spotMarketProxy: address(0x2),
            sUSDProxy: address(0),
            oracle: address(0x4),
            usdc: address(0x5)
        }) {} catch (bytes memory reason) {
            assertEq(bytes4(reason), IEngine.ZeroAddress.selector);
        }
    }

    function test_deploy_oracle_zero_address() public {
        try setup.deploySystem({
            perpsMarketProxy: address(0x1),
            spotMarketProxy: address(0x2),
            sUSDProxy: address(0x3),
            oracle: address(0),
            usdc: address(0x5)
        }) {} catch (bytes memory reason) {
            assertEq(bytes4(reason), IEngine.ZeroAddress.selector);
        }
    }

    function test_deploy_trusted_forwarder_zero_address() public {
        // trusted forwarder is deployed within the deploy script thus
        // this test does not use the setup.deploySystem function
        try new Engine({
            _perpsMarketProxy: address(0x1),
            _spotMarketProxy: address(0x2),
            _sUSDProxy: address(0x3),
            _oracle: address(0x4),
            _trustedForwarder: address(0),
            _usdc: address(0x5)
        }) {} catch (bytes memory reason) {
            assertEq(bytes4(reason), IEngine.ZeroAddress.selector);
        }
    }

    function test_deploy_usdc_zero_address() public {
        try setup.deploySystem({
            perpsMarketProxy: address(0x1),
            spotMarketProxy: address(0x2),
            sUSDProxy: address(0x3),
            oracle: address(0x4),
            usdc: address(0)
        }) {} catch (bytes memory reason) {
            assertEq(bytes4(reason), IEngine.ZeroAddress.selector);
        }
    }
}

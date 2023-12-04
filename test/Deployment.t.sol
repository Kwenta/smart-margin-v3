// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {Engine, Setup} from "script/Deploy.s.sol";
import {IEngine} from "src/interfaces/IEngine.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract DeploymentTest is Test, Setup {
    Setup setup;

    function setUp() public {
        setup = new Setup();
    }

    function test_deploy() public {
        (Engine engine) = setup.deploySystem({
            perpsMarketProxy: address(0x1),
            spotMarketProxy: address(0x2),
            sUSDProxy: address(0x3),
            oracle: address(0x4)
        });

        assertTrue(address(engine) != address(0x0));
    }

    function test_deploy_perps_market_proxy_zero_address() public {
        try setup.deploySystem({
            perpsMarketProxy: address(0),
            spotMarketProxy: address(0x2),
            sUSDProxy: address(0x3),
            oracle: address(0x4)
        }) {} catch (bytes memory reason) {
            assertEq(bytes4(reason), IEngine.ZeroAddress.selector);
        }
    }

    function test_deploy_spot_market_proxy_zero_address() public {
        try setup.deploySystem({
            perpsMarketProxy: address(0x1),
            spotMarketProxy: address(0),
            sUSDProxy: address(0x3),
            oracle: address(0x4)
        }) {} catch (bytes memory reason) {
            assertEq(bytes4(reason), IEngine.ZeroAddress.selector);
        }
    }

    function test_deploy_susd_proxy_zero_address() public {
        try setup.deploySystem({
            perpsMarketProxy: address(0x1),
            spotMarketProxy: address(0x2),
            sUSDProxy: address(0),
            oracle: address(0x4)
        }) {} catch (bytes memory reason) {
            assertEq(bytes4(reason), IEngine.ZeroAddress.selector);
        }
    }

    function test_deploy_oracle_zero_address() public {
        try setup.deploySystem({
            perpsMarketProxy: address(0x1),
            spotMarketProxy: address(0x2),
            sUSDProxy: address(0x3),
            oracle: address(0)
        }) {} catch (bytes memory reason) {
            assertEq(bytes4(reason), IEngine.ZeroAddress.selector);
        }
    }
}

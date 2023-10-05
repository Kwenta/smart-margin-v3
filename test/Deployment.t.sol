// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Engine, Setup} from "script/Deploy.s.sol";
import {IEngine} from "src/interfaces/IEngine.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract DeploymentTest is Test, Setup {
    function test_deploy() public {
        Engine engine = Setup.deploySystem({
            perpsMarketProxy: address(0x1),
            spotMarketProxy: address(0x2),
            sUSDProxy: address(0x3),
            oracle: address(0x4),
            trustedForwarder: address(0x5)
        });

        assertTrue(address(engine) != address(0x0));
    }

    function test_deploy_perps_market_proxy_zero_address() public {
        vm.expectRevert(abi.encodeWithSelector(IEngine.ZeroAddress.selector));

        Setup.deploySystem({
            perpsMarketProxy: address(0),
            spotMarketProxy: address(0x2),
            sUSDProxy: address(0x3),
            oracle: address(0x4),
            trustedForwarder: address(0x5)
        });
    }

    function test_deploy_spot_market_proxy_zero_address() public {
        vm.expectRevert(abi.encodeWithSelector(IEngine.ZeroAddress.selector));

        Setup.deploySystem({
            perpsMarketProxy: address(0x1),
            spotMarketProxy: address(0),
            sUSDProxy: address(0x3),
            oracle: address(0x4),
            trustedForwarder: address(0x5)
        });
    }

    function test_deploy_susd_proxy_zero_address() public {
        vm.expectRevert(abi.encodeWithSelector(IEngine.ZeroAddress.selector));

        Setup.deploySystem({
            perpsMarketProxy: address(0x1),
            spotMarketProxy: address(0x2),
            sUSDProxy: address(0),
            oracle: address(0x4),
            trustedForwarder: address(0x5)
        });
    }

    function test_deploy_oracle_zero_address() public {
        vm.expectRevert(abi.encodeWithSelector(IEngine.ZeroAddress.selector));

        Setup.deploySystem({
            perpsMarketProxy: address(0x1),
            spotMarketProxy: address(0x2),
            sUSDProxy: address(0x3),
            oracle: address(0),
            trustedForwarder: address(0x5)
        });
    }

    function test_deploy_trusted_forwarder_zero_address() public {
        vm.expectRevert(abi.encodeWithSelector(IEngine.ZeroAddress.selector));

        Setup.deploySystem({
            perpsMarketProxy: address(0x1),
            spotMarketProxy: address(0x2),
            sUSDProxy: address(0x3),
            oracle: address(0x4),
            trustedForwarder: address(0)
        });
    }
}

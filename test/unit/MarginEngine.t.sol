// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Auth} from "src/modules/Auth.sol";
import {MarginEngine} from "src/MarginEngine.sol";
import {SUSDHelper, IERC20} from "test/utils/SUSDHelper.sol";
import {
    OPTIMISM_GOERLI_SPOT_MARKET_PROXY,
    OPTIMISM_GOERLI_PERPS_MARKET_PROXY,
    OPTIMISM_GOERLI_SUSD_PROXY
} from "script/utils/parameters/OptimismGoerliParameters.sol";
import {Test} from "lib/forge-std/src/Test.sol";
import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";

contract MarginEngineTest is Test {
    Auth auth;
    MarginEngine marginEngine;
    IPerpsMarketProxy perpsMarketProxy;
    SUSDHelper sUSDHelper;

    function setUp() public {
        vm.rollFork(13_149_245);

        auth = new Auth(OPTIMISM_GOERLI_PERPS_MARKET_PROXY);
        marginEngine = new MarginEngine(
            address(auth), 
            OPTIMISM_GOERLI_PERPS_MARKET_PROXY, 
            OPTIMISM_GOERLI_SPOT_MARKET_PROXY,
            OPTIMISM_GOERLI_SUSD_PROXY
        );

        sUSDHelper = new SUSDHelper();

        perpsMarketProxy = IPerpsMarketProxy(OPTIMISM_GOERLI_PERPS_MARKET_PROXY);
    }
}

contract CreateAccount is MarginEngineTest {
    function test_createAccount() public {
        marginEngine.createAccount();
    }
}

contract AccountMargin is MarginEngineTest {
    uint128 sUSDMarketId = 0;
    uint128 btcUSDMarketId = 1;
    int256 depositAmount = 1000 ether;

    function test_depositCollateral() public {
        sUSDHelper.mint(address(this), uint256(depositAmount));

        uint128 accountId = marginEngine.createAccount();

        IERC20(OPTIMISM_GOERLI_SUSD_PROXY).approve(
            address(marginEngine), type(uint256).max
        );

        marginEngine.depositCollateral(accountId, sUSDMarketId, depositAmount);

        int256 availableMargin = perpsMarketProxy.getAvailableMargin(accountId);
        assertEq(availableMargin, depositAmount);

        uint256 collateralAmountOfSynth =
            perpsMarketProxy.getCollateralAmount(accountId, sUSDMarketId);
        assertEq(collateralAmountOfSynth, uint256(depositAmount));

        uint256 totalCollateralValue =
            perpsMarketProxy.totalCollateralValue(accountId);
        assertEq(totalCollateralValue, uint256(depositAmount));
    }
}

contract Multicallable is MarginEngineTest {}

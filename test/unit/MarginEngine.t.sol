// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Auth} from "src/modules/Auth.sol";
import {Constants} from "test/utils/Constants.sol";
import {MarginEngine} from "src/MarginEngine.sol";
import {Stats} from "src/modules/Stats.sol";
import {SUSDHelper, IERC20} from "test/utils/SUSDHelper.sol";
import {
    OPTIMISM_GOERLI_SPOT_MARKET_PROXY,
    OPTIMISM_GOERLI_PERPS_MARKET_PROXY,
    OPTIMISM_GOERLI_SUSD_PROXY
} from "script/utils/parameters/OptimismGoerliParameters.sol";
import {Test} from "lib/forge-std/src/Test.sol";
import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";

/// @custom:todo make sure tests are named correctly/consistently

contract MarginEngineTest is Test, Constants {
    // SMv3 contracts
    Auth auth;
    MarginEngine marginEngine;
    Stats stats;

    // external contracts
    IPerpsMarketProxy perpsMarketProxy;
    SUSDHelper sUSDHelper;

    // state variables
    uint128 accountId;

    function setUp() public {
        vm.rollFork(13_149_245);

        sUSDHelper = new SUSDHelper();
        perpsMarketProxy = IPerpsMarketProxy(OPTIMISM_GOERLI_PERPS_MARKET_PROXY);

        auth = new Auth(OPTIMISM_GOERLI_PERPS_MARKET_PROXY);

        stats = new Stats(OWNER);

        marginEngine = new MarginEngine(
            address(auth),
            address(stats),
            OPTIMISM_GOERLI_PERPS_MARKET_PROXY, 
            OPTIMISM_GOERLI_SPOT_MARKET_PROXY,
            OPTIMISM_GOERLI_SUSD_PROXY
        );

        vm.startPrank(OWNER);
        stats.registerMarginEngine(address(marginEngine));
        // add other owner based modules here
        vm.stopPrank();

        vm.startPrank(ACTOR);
        accountId = auth.createAccount();
        auth.registerMarginEngine(accountId, address(marginEngine));
        // above can also be done via `auth.createAccount(address(marginEngine))`
        vm.stopPrank();

        sUSDHelper.mint(ACTOR, AMOUNT);
    }
}

contract CollateralManagement is MarginEngineTest {
    function test_depositCollateral_availableMargin() public {
        vm.startPrank(ACTOR);

        IERC20(OPTIMISM_GOERLI_SUSD_PROXY).approve(
            address(marginEngine), type(uint256).max
        );

        marginEngine.depositCollateral(
            accountId, SUSD_MARKET_ID, int256(AMOUNT)
        );

        vm.stopPrank();

        int256 availableMargin = perpsMarketProxy.getAvailableMargin(accountId);
        assertEq(availableMargin, int256(AMOUNT));
    }

    function test_depositCollateral_collateralAmount() public {
        vm.startPrank(ACTOR);

        IERC20(OPTIMISM_GOERLI_SUSD_PROXY).approve(
            address(marginEngine), type(uint256).max
        );

        marginEngine.depositCollateral(
            accountId, SUSD_MARKET_ID, int256(AMOUNT)
        );

        vm.stopPrank();

        uint256 collateralAmountOfSynth =
            perpsMarketProxy.getCollateralAmount(accountId, SUSD_MARKET_ID);
        assertEq(collateralAmountOfSynth, AMOUNT);
    }

    function test_depositCollateral_totalCollateralValue() public {
        vm.startPrank(ACTOR);

        IERC20(OPTIMISM_GOERLI_SUSD_PROXY).approve(
            address(marginEngine), type(uint256).max
        );

        marginEngine.depositCollateral(
            accountId, SUSD_MARKET_ID, int256(AMOUNT)
        );

        vm.stopPrank();

        uint256 totalCollateralValue =
            perpsMarketProxy.totalCollateralValue(accountId);
        assertEq(totalCollateralValue, AMOUNT);
    }
}

contract AsyncOrderManagement is MarginEngineTest {}

contract Multicallable is MarginEngineTest {}

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
        vm.rollFork(GOERLI_BLOCK_NUMBER);

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

        marginEngine.depositCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        vm.stopPrank();

        int256 availableMargin = perpsMarketProxy.getAvailableMargin(accountId);
        assertEq(availableMargin, int256(AMOUNT));
    }

    function test_depositCollateral_collateralAmount() public {
        vm.startPrank(ACTOR);

        IERC20(OPTIMISM_GOERLI_SUSD_PROXY).approve(
            address(marginEngine), type(uint256).max
        );

        marginEngine.depositCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        vm.stopPrank();

        uint256 collateralAmountOfSynth =
            perpsMarketProxy.getCollateralAmount(accountId, SUSD_SPOT_MARKET_ID);
        assertEq(collateralAmountOfSynth, AMOUNT);
    }

    function test_depositCollateral_totalCollateralValue() public {
        vm.startPrank(ACTOR);

        IERC20(OPTIMISM_GOERLI_SUSD_PROXY).approve(
            address(marginEngine), type(uint256).max
        );

        marginEngine.depositCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        vm.stopPrank();

        uint256 totalCollateralValue =
            perpsMarketProxy.totalCollateralValue(accountId);
        assertEq(totalCollateralValue, AMOUNT);
    }

    /// @custom:todo test withdrawCollateral
}

contract AsyncOrderManagement is MarginEngineTest {
    function test_commitOrder() public {
        vm.startPrank(ACTOR);

        IERC20(OPTIMISM_GOERLI_SUSD_PROXY).approve(
            address(marginEngine), type(uint256).max
        );

        marginEngine.depositCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        marginEngine.commitOrder({
            _perpsMarketId: SETH_PERPS_MARKET_ID,
            _accountId: accountId,
            _sizeDelta: 1 ether,
            _settlementStrategyId: 0, // @custom:todo what is this?
            _acceptablePrice: type(uint256).max,
            _referrer: REFERRER
        });
    }

    /// @cutsoom:todo test commitOrder: Market that does not exist
    /// @custom:todo test commitOrder: Market that is paused
    /// @custom:todo test commitOrder: Account does not have enough collateral/margin
    /// @custom:todo test commitOrder: Position size exceeds max leverage
}

contract Multicallable is MarginEngineTest {
    function test_multicall_depositCollateral_commitOrder() public {
        vm.startPrank(ACTOR);

        IERC20(OPTIMISM_GOERLI_SUSD_PROXY).approve(
            address(marginEngine), type(uint256).max
        );

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(MarginEngine.depositCollateral.selector, accountId, SUSD_SPOT_MARKET_ID, int256(AMOUNT));
        data[1] = abi.encodeWithSelector(MarginEngine.commitOrder.selector, SETH_PERPS_MARKET_ID, accountId, 1 ether, 0, type(uint256).max, REFERRER);

        marginEngine.multicall(data);
    }
}

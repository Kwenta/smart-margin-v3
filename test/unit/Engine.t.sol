// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

// foundry
import {Test} from "lib/forge-std/src/Test.sol";

// engine
import {Engine} from "src/Engine.sol";

// synthetix v3
import {ICoreProxy} from "src/interfaces/synthetix/ICoreProxy.sol";
import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";

// tokens
import {IERC20, SUSDHelper} from "test/utils/SUSDHelper.sol";

// constants
import {Constants} from "test/utils/Constants.sol";
import {
    OPTIMISM_GOERLI_CORE_PROXY,
    OPTIMISM_GOERLI_SPOT_MARKET_PROXY,
    OPTIMISM_GOERLI_PERPS_MARKET_PROXY
} from "script/utils/parameters/OptimismGoerliParameters.sol";

contract EngineTest is Test, Constants {
    // margin engine
    Engine engine;

    // synthetix v3
    ICoreProxy coreProxy;
    IPerpsMarketProxy perpsMarketProxy;

    // tokens
    IERC20 sUSD;
    SUSDHelper sUSDHelper;

    // test state
    uint128 accountId;

    function setUp() public {
        vm.rollFork(GOERLI_BLOCK_NUMBER);

        sUSDHelper = new SUSDHelper();
        perpsMarketProxy = IPerpsMarketProxy(OPTIMISM_GOERLI_PERPS_MARKET_PROXY);
        coreProxy = ICoreProxy(OPTIMISM_GOERLI_CORE_PROXY);

        sUSD = IERC20(coreProxy.getUsdToken());

        engine = new Engine(
            OPTIMISM_GOERLI_PERPS_MARKET_PROXY, 
            OPTIMISM_GOERLI_SPOT_MARKET_PROXY,
            address(sUSD)
        );

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

contract Collateral is EngineTest {
    function test_depositCollateral() public {
        uint256 preBalance = sUSD.balanceOf(ACTOR);

        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        vm.stopPrank();

        uint256 postBalance = sUSD.balanceOf(ACTOR);

        assertEq(postBalance, preBalance - AMOUNT);
    }

    function test_depositCollateral_availableMargin() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
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

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
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

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        vm.stopPrank();

        uint256 totalCollateralValue =
            perpsMarketProxy.totalCollateralValue(accountId);
        assertEq(totalCollateralValue, AMOUNT);
    }

    function test_withdrawCollateral() public {
        uint256 preBalance = sUSD.balanceOf(ACTOR);

        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: -int256(AMOUNT)
        });

        vm.stopPrank();

        uint256 postBalance = sUSD.balanceOf(ACTOR);

        assertEq(postBalance, preBalance);
    }

    function test_withdrawCollateral_availableMargin() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: -int256(AMOUNT)
        });

        vm.stopPrank();

        int256 availableMargin = perpsMarketProxy.getAvailableMargin(accountId);
        assertEq(availableMargin, 0);
    }

    function test_withdrawCollateral_collateralAmount() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: -int256(AMOUNT)
        });

        vm.stopPrank();

        uint256 collateralAmountOfSynth =
            perpsMarketProxy.getCollateralAmount(accountId, SUSD_SPOT_MARKET_ID);
        assertEq(collateralAmountOfSynth, 0);
    }

    function test_withdrawCollateral_totalCollateralValue() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: -int256(AMOUNT)
        });

        vm.stopPrank();

        uint256 totalCollateralValue =
            perpsMarketProxy.totalCollateralValue(accountId);
        assertEq(totalCollateralValue, 0);
    }
}

contract AsyncOrder is EngineTest {
    function test_commitOrder() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        engine.commitOrder({
            _perpsMarketId: SETH_PERPS_MARKET_ID,
            _accountId: accountId,
            _sizeDelta: 1 ether,
            _settlementStrategyId: 0,
            _acceptablePrice: type(uint256).max
        });
    }

    /// @cutsoom:todo test commitOrder: Market that does not exist
    /// @custom:todo test commitOrder: Market that is paused
    /// @custom:todo test commitOrder: Account does not have enough collateral/margin
    /// @custom:todo test commitOrder: Position size exceeds max leverage
}

contract Multicallable is EngineTest {
    function test_multicall_depositCollateral_commitOrder() public {
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(
            engine.modifyCollateral.selector,
            accountId,
            SUSD_SPOT_MARKET_ID,
            int256(AMOUNT)
        );
        data[1] = abi.encodeWithSelector(
            engine.commitOrder.selector,
            SETH_PERPS_MARKET_ID,
            accountId,
            1 ether,
            0,
            type(uint256).max,
            REFERRER
        );

        engine.multicall(data);
    }
}

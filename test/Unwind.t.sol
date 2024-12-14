// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

import {Bootstrap, Engine} from "test/utils/Bootstrap.sol";
import {IEngine} from "src/interfaces/IEngine.sol";
import {MathLib} from "src/libraries/MathLib.sol";

contract UnwindTest is Bootstrap {
    using MathLib for int128;
    using MathLib for int256;
    using MathLib for uint256;

    address public constant DEBT_ACTOR =
        address(0x72A8EA777f5Aa58a1E5a405931e2ccb455B60088);
    uint128 public constant ACCOUNT_ID =
        170_141_183_460_469_231_731_687_303_715_884_105_766;
    uint256 public constant INITIAL_DEBT = 8_381_435_606_953_380_465;

    address constant USDC_ADDR = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address constant WETH_ADDR = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    function setUp() public {
        vm.rollFork(BASE_BLOCK_NUMBER);
        initializeBase();

        synthMinter.mint_sUSD(DEBT_ACTOR, AMOUNT);

        /// @dev this is needed because MWS hardcodes the live Engine contract address
        /// therefore we cannot use our boostrap test state, we must fork
        // vm.startPrank(DEBT_ACTOR);
        // perpsMarketProxy.grantPermission({
        //     accountId: ACCOUNT_ID,
        //     permission: ADMIN_PERMISSION,
        //     user: address(engine)
        // });
        // vm.stopPrank();
    }

    function test_unwindCollateral_UNAUTHORIZED() public {
        vm.expectRevert(abi.encodeWithSelector(IEngine.Unauthorized.selector));
        engine.unwindCollateral(accountId, 1, 1, address(0), 1, 1, 1, "");
    }

    function test_unwindCollateralETH_UNAUTHORIZED() public {
        vm.expectRevert(abi.encodeWithSelector(IEngine.Unauthorized.selector));
        engine.unwindCollateralETH(accountId, 1, address(0), 1, 1, 1, "");
    }

    function test_unwindCollateral_s() public {
        /// @custom:todo Get a debt position on Base to fork
        // uint256 initialAccountDebt = perpsMarketProxy.debt(ACCOUNT_ID);
        // assertEq(initialAccountDebt, INITIAL_DEBT);

        // int256 withdrawableMargin =
        //     perpsMarketProxy.getWithdrawableMargin(ACCOUNT_ID);

        // /// While there is debt, withdrawable margin should be 0
        // assertEq(withdrawableMargin, 0);

        // vm.startPrank(DEBT_ACTOR);

        // uint24 FEE_30 = 3000;
        // bytes memory weth_path = abi.encodePacked(USDC_ADDR, FEE_30, WETH_ADDR);

        // engine.unwindCollateral({
        //     _accountId: ACCOUNT_ID,
        //     _collateralId: 4,
        //     _collateralAmount: 38_000_000_000_000_000,
        //     _collateral: WETH_ADDR,
        //     _zapMinAmountOut: 829_762_200_000_000_000,
        //     _unwrapMinAmountOut: 3_796_200_000_000_000,
        //     _swapMaxAmountIn: 3_824_606_425_619_680,
        //     _path: weth_path
        // });

        // vm.stopPrank();

        // withdrawableMargin = perpsMarketProxy.getWithdrawableMargin(ACCOUNT_ID);
        // assertGt(withdrawableMargin, 0);
    }
}

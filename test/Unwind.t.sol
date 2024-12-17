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
        address(0x325cd6b3CD80EDB102ac78848f5B127eB6DB13f3);
    uint128 public constant ACCOUNT_ID =
        170_141_183_460_469_231_731_687_303_715_884_105_747;
    uint256 public constant INITIAL_DEBT = 2_983_003_117_413_866_988;
    uint256 public constant BASE_BLOCK_NUMBER_WITH_DEBT = 23_805_461;
    uint256 public constant SWAP_AMOUNT = 1e18;

    bytes swapPath;
    string pathId;

    function setUp() public {
        string memory BASE_RPC = vm.envString("BASE_RPC_URL");
        uint256 baseForkCurrentBlock = vm.createFork(BASE_RPC);
        vm.selectFork(baseForkCurrentBlock);
        initializeBase();

        synthMinter.mint_sUSD(DEBT_ACTOR, AMOUNT);

        /// @dev this is needed because MWS hardcodes the live Engine contract address
        /// therefore we cannot use our boostrap test state, we must fork
        vm.startPrank(DEBT_ACTOR);
        perpsMarketProxy.grantPermission({
            accountId: ACCOUNT_ID,
            permission: ADMIN_PERMISSION,
            user: address(engine)
        });
        vm.stopPrank();
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
        uint256 initialAccountDebt = perpsMarketProxy.debt(ACCOUNT_ID);
        assertEq(initialAccountDebt, INITIAL_DEBT);

        int256 withdrawableMargin =
            perpsMarketProxy.getWithdrawableMargin(ACCOUNT_ID);

        /// @dev While there is debt, withdrawable margin should be 0
        assertEq(withdrawableMargin, 0);

        vm.startPrank(DEBT_ACTOR);

        pathId = getOdosQuotePathId(
            BASE_CHAIN_ID, address(WETH), SWAP_AMOUNT, address(USDC)
        );

        swapPath = getAssemblePath(pathId);

        engine.unwindCollateral({
            _accountId: ACCOUNT_ID,
            _collateralId: WETH_SYNTH_MARKET_ID,
            _collateralAmount: 1_100_000_000_000_000,
            _collateral: address(WETH),
            // _zapMinAmountOut: 829_762_200_000_000_000,
            // _unwrapMinAmountOut: 3_796_200_000_000_000,
            // _swapAmountIn: 3_824_606_425_619_680,
            _zapMinAmountOut: 1,
            _unwrapMinAmountOut: 1,
            _swapAmountIn: SWAP_AMOUNT,
            _path: swapPath
        });

        // vm.stopPrank();

        // withdrawableMargin = perpsMarketProxy.getWithdrawableMargin(ACCOUNT_ID);
        // assertGt(withdrawableMargin, 0);
    }
}

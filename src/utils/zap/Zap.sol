// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Errors} from "./Errors.sol";
import {IPool} from "./interfaces/IAave.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {ICore, IPerpsMarket, ISpotMarket} from "./interfaces/ISynthetix.sol";
import {IUniswap} from "./interfaces/IUniswap.sol";

/// @title Zap
/// @custom:synthetix Zap USDC into and out of USDx
/// @custom:aave Flashloan USDC to unwind synthetix collateral
/// @custom:uniswap Swap unwound collateral for USDC to repay flashloan
/// @dev Idle token balances are not safe
/// @dev Intended for standalone use; do not inherit
/// @author @jaredborders
/// @author @barrasso
/// @author @Flocqst
contract Zap is Errors {

    /// @custom:synthetix
    address public immutable USDC;
    address public immutable USDX;
    address public immutable SPOT_MARKET;
    address public immutable PERPS_MARKET;
    address public immutable CORE;
    address public immutable REFERRER;
    uint128 public immutable SUSDC_SPOT_ID;
    uint128 public immutable PREFFERED_POOL_ID;
    bytes32 public immutable MODIFY_PERMISSION;
    bytes32 public immutable BURN_PERMISSION;
    uint128 public immutable USDX_ID;

    /// @custom:aave
    address public immutable AAVE;
    uint16 public immutable REFERRAL_CODE;

    /// @custom:uniswap
    address public immutable UNISWAP;
    uint24 public immutable FEE_TIER;

    constructor(
        address _usdc,
        address _usdx,
        address _spotMarket,
        address _perpsMarket,
        address _core,
        address _referrer,
        uint128 _susdcSpotId,
        address _aave,
        address _uniswap
    ) {
        /// @custom:synthetix
        USDC = _usdc;
        USDX = _usdx;
        SPOT_MARKET = _spotMarket;
        PERPS_MARKET = _perpsMarket;
        CORE = _core;
        REFERRER = _referrer;
        SUSDC_SPOT_ID = _susdcSpotId;
        PREFFERED_POOL_ID = ICore(CORE).getPreferredPool();
        MODIFY_PERMISSION = "PERPS_MODIFY_COLLATERAL";
        BURN_PERMISSION = "BURN";
        USDX_ID = 0;

        /// @custom:aave
        AAVE = _aave;
        REFERRAL_CODE = 0;

        /// @custom:uniswap
        UNISWAP = _uniswap;
        FEE_TIER = 3000;
    }

    /*//////////////////////////////////////////////////////////////
                                  ZAP
    //////////////////////////////////////////////////////////////*/

    function zapIn(
        uint256 _amount,
        uint256 _tolerance,
        address _receiver
    )
        external
        returns (uint256 zapped)
    {
        _pull(USDC, msg.sender, _amount);
        zapped = _zapIn(_amount, _tolerance);
        _push(USDX, _receiver, zapped);
    }

    function _zapIn(
        uint256 _amount,
        uint256 _tolerance
    )
        internal
        returns (uint256 zapped)
    {
        zapped = _wrap(USDC, SUSDC_SPOT_ID, _amount, _tolerance);
        zapped = _sell(SUSDC_SPOT_ID, zapped, _tolerance);
    }

    function zapOut(
        uint256 _amount,
        uint256 _tolerance,
        address _receiver
    )
        external
        returns (uint256 zapped)
    {
        _pull(USDX, msg.sender, _amount);
        zapped = _zapOut(_amount, _tolerance);
        _push(USDC, _receiver, zapped);
    }

    function _zapOut(
        uint256 _amount,
        uint256 _tolerance
    )
        internal
        returns (uint256 zapped)
    {
        (zapped,) = _buy(SUSDC_SPOT_ID, _amount, _tolerance);
        zapped = _unwrap(SUSDC_SPOT_ID, zapped, _tolerance);
    }

    /*//////////////////////////////////////////////////////////////
                            WRAP AND UNWRAP
    //////////////////////////////////////////////////////////////*/

    function wrap(
        address _token,
        uint128 _synthId,
        uint256 _amount,
        uint256 _tolerance,
        address _receiver
    )
        external
        returns (uint256 wrapped)
    {
        _pull(_token, msg.sender, _amount);
        wrapped = _wrap(_token, _synthId, _amount, _tolerance);
        address synth = ISpotMarket(SPOT_MARKET).getSynth(_synthId);
        _push(synth, _receiver, wrapped);
    }

    function _wrap(
        address _token,
        uint128 _synthId,
        uint256 _amount,
        uint256 _tolerance
    )
        internal
        returns (uint256 wrapped)
    {
        IERC20(_token).approve(SPOT_MARKET, _amount);

        try ISpotMarket(SPOT_MARKET).wrap({
            marketId: _synthId,
            wrapAmount: _amount,
            minAmountReceived: _tolerance
        }) returns (uint256 amount, ISpotMarket.Data memory) {
            wrapped = amount;
        } catch Error(string memory reason) {
            revert WrapFailed(reason);
        }
    }

    function unwrap(
        address _token,
        uint128 _synthId,
        uint256 _amount,
        uint256 _tolerance,
        address _receiver
    )
        external
        returns (uint256 unwrapped)
    {
        address synth = ISpotMarket(SPOT_MARKET).getSynth(_synthId);
        _pull(synth, msg.sender, _amount);
        unwrapped = _unwrap(_synthId, _amount, _tolerance);
        _push(_token, _receiver, unwrapped);
    }

    function _unwrap(
        uint128 _synthId,
        uint256 _amount,
        uint256 _tolerance
    )
        private
        returns (uint256 unwrapped)
    {
        address synth = ISpotMarket(SPOT_MARKET).getSynth(_synthId);
        IERC20(synth).approve(SPOT_MARKET, _amount);
        try ISpotMarket(SPOT_MARKET).unwrap({
            marketId: _synthId,
            unwrapAmount: _amount,
            minAmountReceived: _tolerance
        }) returns (uint256 amount, ISpotMarket.Data memory) {
            unwrapped = amount;
        } catch Error(string memory reason) {
            revert UnwrapFailed(reason);
        }
    }

    /*//////////////////////////////////////////////////////////////
                              BUY AND SELL
    //////////////////////////////////////////////////////////////*/

    function buy(
        uint128 _synthId,
        uint256 _amount,
        uint256 _tolerance,
        address _receiver
    )
        external
        returns (uint256 received, address synth)
    {
        _pull(USDX, msg.sender, _amount);
        (received, synth) = _buy(_synthId, _amount, _tolerance);
        _push(synth, _receiver, received);
    }

    function _buy(
        uint128 _synthId,
        uint256 _amount,
        uint256 _tolerance
    )
        internal
        returns (uint256 received, address synth)
    {
        IERC20(USDX).approve(SPOT_MARKET, _amount);
        try ISpotMarket(SPOT_MARKET).buy({
            marketId: _synthId,
            usdAmount: _amount,
            minAmountReceived: _tolerance,
            referrer: REFERRER
        }) returns (uint256 amount, ISpotMarket.Data memory) {
            received = amount;
            synth = ISpotMarket(SPOT_MARKET).getSynth(_synthId);
        } catch Error(string memory reason) {
            revert BuyFailed(reason);
        }
    }

    function sell(
        uint128 _synthId,
        uint256 _amount,
        uint256 _tolerance,
        address _receiver
    )
        external
        returns (uint256 received)
    {
        address synth = ISpotMarket(SPOT_MARKET).getSynth(_synthId);
        _pull(synth, msg.sender, _amount);
        received = _sell(_synthId, _amount, _tolerance);
        _push(USDX, _receiver, received);
    }

    function _sell(
        uint128 _synthId,
        uint256 _amount,
        uint256 _tolerance
    )
        internal
        returns (uint256 received)
    {
        address synth = ISpotMarket(SPOT_MARKET).getSynth(_synthId);
        IERC20(synth).approve(SPOT_MARKET, _amount);
        try ISpotMarket(SPOT_MARKET).sell({
            marketId: _synthId,
            synthAmount: _amount,
            minUsdAmount: _tolerance,
            referrer: REFERRER
        }) returns (uint256 amount, ISpotMarket.Data memory) {
            received = amount;
        } catch Error(string memory reason) {
            revert SellFailed(reason);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                  AAVE
    //////////////////////////////////////////////////////////////*/

    function requestFlashloan(
        uint256 _usdcLoan,
        uint256 _collateralAmount,
        address _collateral,
        uint128 _accountId,
        uint128 _synthId,
        uint256 _tolerance,
        uint256 _swapTolerance,
        address receiver
    )
        external
    {
        bytes memory params = abi.encode(
            _collateralAmount,
            _collateral,
            _accountId,
            _synthId,
            _tolerance,
            _swapTolerance,
            receiver
        );
        IPool(AAVE).flashLoanSimple({
            receiverAddress: address(this),
            asset: USDC,
            amount: _usdcLoan,
            params: params,
            referralCode: REFERRAL_CODE
        });
    }

    function executeOperation(
        address,
        uint256 amount,
        uint256 premium,
        address,
        bytes calldata params
    )
        external
        returns (bool)
    {
        (
            uint256 collateralAmount,
            address collateral,
            uint128 accountId,
            uint128 synthId,
            uint256 tolerance,
            uint256 swapTolerance,
            address receiver
        ) = abi.decode(
            params,
            (uint256, address, uint128, uint128, uint256, uint256, address)
        );
        uint256 unwoundCollateral = _unwind(
            amount,
            collateralAmount,
            collateral,
            accountId,
            synthId,
            tolerance,
            swapTolerance
        );
        uint256 debt = amount + premium;
        uint256 differece = unwoundCollateral - debt;
        IERC20(USDC).approve(AAVE, debt);
        return IERC20(collateral).transfer(receiver, differece);
    }

    function _unwind(
        uint256 _usdcLoan,
        uint256 _collateralAmount,
        address _collateral,
        uint128 _accountId,
        uint128 _synthId,
        uint256 _tolerance,
        uint256 _swapTolerance
    )
        internal
        returns (uint256 unwound)
    {
        uint256 usdxAmount = _zapIn(_usdcLoan, _tolerance);
        _burn(usdxAmount, _accountId);
        _withdraw(_synthId, _collateralAmount, _accountId);
        unwound = _unwrap(_synthId, _collateralAmount, _tolerance);
        if (_synthId != SUSDC_SPOT_ID) {
            _swap(_collateral, unwound, _swapTolerance);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                  BURN
    //////////////////////////////////////////////////////////////*/

    function burn(uint256 _amount, uint128 _accountId) external {
        _pull(USDX, msg.sender, _amount);
        _burn(_amount, _accountId);
    }

    /// @custom:account permission required: "BURN"
    function _burn(uint256 _amount, uint128 _accountId) internal {
        IERC20(USDX).approve(CORE, _amount);
        ICore(CORE).burnUsd(_accountId, PREFFERED_POOL_ID, USDC, _amount);
        ICore(CORE).renouncePermission(_accountId, BURN_PERMISSION);
    }

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/

    function withdraw(
        uint128 _synthId,
        uint256 _amount,
        uint128 _accountId,
        address _receiver
    )
        external
    {
        _withdraw(_synthId, _amount, _accountId);
        address synth = _synthId == USDX_ID
            ? USDX
            : ISpotMarket(SPOT_MARKET).getSynth(_synthId);
        _push(synth, _receiver, _amount);
    }

    /// @custom:account permission required: "PERPS_MODIFY_COLLATERAL"
    function _withdraw(
        uint128 _synthId,
        uint256 _amount,
        uint128 _accountId
    )
        internal
    {
        IPerpsMarket market = IPerpsMarket(PERPS_MARKET);
        market.modifyCollateral({
            accountId: _accountId,
            synthMarketId: _synthId,
            amountDelta: -int256(_amount)
        });
        market.renouncePermission(_accountId, MODIFY_PERMISSION);
    }

    /*//////////////////////////////////////////////////////////////
                                UNISWAP
    //////////////////////////////////////////////////////////////*/

    function swap(
        address _from,
        uint256 _amount,
        uint256 _tolerance,
        address _receiver
    )
        external
        returns (uint256 received)
    {
        _pull(_from, msg.sender, _amount);
        received = _swap(_from, _amount, _tolerance);
        _push(USDC, _receiver, received);
    }

    function _swap(
        address _from,
        uint256 _amount,
        uint256 _tolerance
    )
        internal
        returns (uint256 received)
    {
        IERC20(_from).approve(UNISWAP, _amount);
        IUniswap.ExactInputSingleParams memory params = IUniswap
            .ExactInputSingleParams({
            tokenIn: _from,
            tokenOut: USDC,
            fee: FEE_TIER,
            recipient: address(this),
            amountIn: _amount,
            amountOutMinimum: _tolerance,
            sqrtPriceLimitX96: 0
        });

        try IUniswap(UNISWAP).exactInputSingle(params) returns (
            uint256 amountOut
        ) {
            received = amountOut;
        } catch Error(string memory reason) {
            revert SwapFailed(reason);
        }
    }

    /*//////////////////////////////////////////////////////////////
                               TRANSFERS
    //////////////////////////////////////////////////////////////*/

    function _pull(
        address _token,
        address _from,
        uint256 _amount
    )
        internal
        returns (bool success)
    {
        IERC20 token = IERC20(_token);
        success = token.transferFrom(_from, address(this), _amount);
    }

    function _push(
        address _token,
        address _receiver,
        uint256 _amount
    )
        internal
        returns (bool success)
    {
        if (_receiver == address(this)) {
            success = true;
        } else {
            IERC20 token = IERC20(_token);
            success = token.transfer(_receiver, _amount);
        }
    }

}

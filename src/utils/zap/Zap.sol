// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IPool} from "./interfaces/IAave.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IPerpsMarket, ISpotMarket} from "./interfaces/ISynthetix.sol";
import {IQuoter, IRouter} from "./interfaces/IUniswap.sol";
import {Errors} from "./utils/Errors.sol";
import {Reentrancy} from "./utils/Reentrancy.sol";

/// @title zap
/// @custom:synthetix zap USDC into and out of USDx
/// @custom:aave flash loan USDC to unwind synthetix collateral
/// @custom:uniswap swap unwound collateral for USDC to repay flashloan
/// @dev idle token balances are not safe
/// @dev intended for standalone use; do not inherit
/// @author @jaredborders
/// @author @flocqst
/// @author @barrasso
/// @author @moss-eth
contract Zap is Reentrancy, Errors {
    /// @custom:circle
    address public immutable USDC;

    /// @custom:synthetix
    address public immutable USDX;
    address public immutable SPOT_MARKET;
    address public immutable PERPS_MARKET;
    address public immutable CORE;
    address public immutable REFERRER;
    uint128 public immutable SUSDC_SPOT_ID;
    bytes32 public immutable MODIFY_PERMISSION;
    bytes32 public immutable BURN_PERMISSION;
    uint128 public immutable USDX_ID;

    /// @custom:aave
    address public immutable AAVE;
    uint16 public immutable REFERRAL_CODE;

    /// @custom:uniswap
    address public immutable ROUTER;
    address public immutable QUOTER;
    uint24 public immutable FEE_TIER;

    constructor(
        address _usdc,
        address _usdx,
        address _spotMarket,
        address _perpsMarket,
        address _referrer,
        uint128 _susdcSpotId,
        address _aave,
        address _router,
        address _quoter
    ) {
        /// @custom:circle
        USDC = _usdc;

        /// @custom:synthetix
        USDX = _usdx;
        SPOT_MARKET = _spotMarket;
        PERPS_MARKET = _perpsMarket;
        REFERRER = _referrer;
        SUSDC_SPOT_ID = _susdcSpotId;
        MODIFY_PERMISSION = "PERPS_MODIFY_COLLATERAL";
        BURN_PERMISSION = "BURN";
        USDX_ID = 0;

        /// @custom:aave
        AAVE = _aave;
        REFERRAL_CODE = 0;

        /// @custom:uniswap
        ROUTER = _router;
        QUOTER = _quoter;
        FEE_TIER = 3000;
    }

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice validate caller is authorized to modify synthetix perp position
    /// @param _accountId synthetix perp market account id
    modifier isAuthorized(uint128 _accountId) {
        bool authorized = IPerpsMarket(PERPS_MARKET).isAuthorized(
            _accountId, MODIFY_PERMISSION, msg.sender
        );
        require(authorized, NotPermitted());
        _;
    }

    /// @notice validate caller is Aave lending pool
    modifier onlyAave() {
        require(msg.sender == AAVE, OnlyAave(msg.sender));
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                  ZAP
    //////////////////////////////////////////////////////////////*/

    /// @notice zap USDC into USDx
    /// @dev caller must grant USDC allowance to this contract
    /// @param _amount amount of USDC to zap
    /// @param _tolerance acceptable slippage for wrapping and selling
    /// @param _receiver address to receive USDx
    /// @return zapped amount of USDx received
    function zapIn(uint256 _amount, uint256 _tolerance, address _receiver)
        external
        returns (uint256 zapped)
    {
        _pull(USDC, msg.sender, _amount);
        zapped = _zapIn(_amount, _tolerance);
        _push(USDX, _receiver, zapped);
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold the zapped USDx
    function _zapIn(uint256 _amount, uint256 _tolerance)
        internal
        returns (uint256 zapped)
    {
        zapped = _wrap(USDC, SUSDC_SPOT_ID, _amount, _tolerance);
        zapped = _sell(SUSDC_SPOT_ID, zapped, _tolerance);
    }

    /// @notice zap USDx into USDC
    /// @dev caller must grant USDx allowance to this contract
    /// @param _amount amount of USDx to zap
    /// @param _tolerance acceptable slippage for buying and unwrapping
    /// @param _receiver address to receive USDC
    /// @return zapped amount of USDC received
    function zapOut(uint256 _amount, uint256 _tolerance, address _receiver)
        external
        returns (uint256 zapped)
    {
        _pull(USDX, msg.sender, _amount);
        zapped = _zapOut(_amount, _tolerance);
        _push(USDC, _receiver, zapped);
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold the zapped USDC
    function _zapOut(uint256 _amount, uint256 _tolerance)
        internal
        returns (uint256 zapped)
    {
        (zapped,) = _buy(SUSDC_SPOT_ID, _amount, _tolerance);
        zapped = _unwrap(SUSDC_SPOT_ID, zapped, _tolerance);
    }

    /*//////////////////////////////////////////////////////////////
                            WRAP AND UNWRAP
    //////////////////////////////////////////////////////////////*/

    /// @notice wrap collateral via synthetix spot market
    /// @dev caller must grant token allowance to this contract
    /// @custom:synth -> synthetix token representation of wrapped collateral
    /// @param _token address of token to wrap
    /// @param _synthId synthetix market id of synth to wrap into
    /// @param _amount amount of token to wrap
    /// @param _tolerance acceptable slippage for wrapping
    /// @param _receiver address to receive wrapped synth
    /// @return wrapped amount of synth received
    function wrap(
        address _token,
        uint128 _synthId,
        uint256 _amount,
        uint256 _tolerance,
        address _receiver
    ) external returns (uint256 wrapped) {
        _pull(_token, msg.sender, _amount);
        wrapped = _wrap(_token, _synthId, _amount, _tolerance);
        _push(ISpotMarket(SPOT_MARKET).getSynth(_synthId), _receiver, wrapped);
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold the wrapped synth
    function _wrap(
        address _token,
        uint128 _synthId,
        uint256 _amount,
        uint256 _tolerance
    ) internal returns (uint256 wrapped) {
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

    /// @notice unwrap collateral via synthetix spot market
    /// @dev caller must grant synth allowance to this contract
    /// @custom:synth -> synthetix token representation of wrapped collateral
    /// @param _token address of token to unwrap into
    /// @param _synthId synthetix market id of synth to unwrap
    /// @param _amount amount of synth to unwrap
    /// @param _tolerance acceptable slippage for unwrapping
    /// @param _receiver address to receive unwrapped token
    /// @return unwrapped amount of token received
    function unwrap(
        address _token,
        uint128 _synthId,
        uint256 _amount,
        uint256 _tolerance,
        address _receiver
    ) external returns (uint256 unwrapped) {
        address synth = ISpotMarket(SPOT_MARKET).getSynth(_synthId);
        _pull(synth, msg.sender, _amount);
        unwrapped = _unwrap(_synthId, _amount, _tolerance);
        _push(_token, _receiver, unwrapped);
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold the unwrapped token
    function _unwrap(uint128 _synthId, uint256 _amount, uint256 _tolerance)
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

    /// @notice buy synth via synthetix spot market
    /// @dev caller must grant USDX allowance to this contract
    /// @param _synthId synthetix market id of synth to buy
    /// @param _amount amount of USDX to spend
    /// @param _tolerance acceptable slippage for buying
    /// @param _receiver address to receive synth
    /// @return received amount of synth
    function buy(
        uint128 _synthId,
        uint256 _amount,
        uint256 _tolerance,
        address _receiver
    ) external returns (uint256 received, address synth) {
        _pull(USDX, msg.sender, _amount);
        (received, synth) = _buy(_synthId, _amount, _tolerance);
        _push(synth, _receiver, received);
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold the bought synth
    function _buy(uint128 _synthId, uint256 _amount, uint256 _tolerance)
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

    /// @notice sell synth via synthetix spot market
    /// @dev caller must grant synth allowance to this contract
    /// @param _synthId synthetix market id of synth to sell
    /// @param _amount amount of synth to sell
    /// @param _tolerance acceptable slippage for selling
    /// @param _receiver address to receive USDX
    /// @return received amount of USDX
    function sell(
        uint128 _synthId,
        uint256 _amount,
        uint256 _tolerance,
        address _receiver
    ) external returns (uint256 received) {
        address synth = ISpotMarket(SPOT_MARKET).getSynth(_synthId);
        _pull(synth, msg.sender, _amount);
        received = _sell(_synthId, _amount, _tolerance);
        _push(USDX, _receiver, received);
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold the sold USDX
    function _sell(uint128 _synthId, uint256 _amount, uint256 _tolerance)
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
                           UNWIND COLLATERAL
    //////////////////////////////////////////////////////////////*/

    /// @notice unwind synthetix perp position collateral
    /// @dev caller must grant USDC allowance to this contract
    /// @custom:synthetix RBAC permission required: "PERPS_MODIFY_COLLATERAL"
    /// @param _accountId synthetix perp market account id
    /// @param _collateralId synthetix market id of collateral
    /// @param _collateralAmount amount of collateral to unwind
    /// @param _collateral address of collateral to unwind
    /// @param _zapTolerance acceptable slippage for zapping
    /// @param _unwrapTolerance acceptable slippage for unwrapping
    /// @param _swapTolerance acceptable slippage for swapping
    /// @param _receiver address to receive unwound collateral
    function unwind(
        uint128 _accountId,
        uint128 _collateralId,
        uint256 _collateralAmount,
        address _collateral,
        uint256 _zapTolerance,
        uint256 _unwrapTolerance,
        uint256 _swapTolerance,
        address _receiver
    ) external isAuthorized(_accountId) requireStage(Stage.UNSET) {
        stage = Stage.LEVEL1;

        bytes memory params = abi.encode(
            _accountId,
            _collateralId,
            _collateralAmount,
            _collateral,
            _zapTolerance,
            _unwrapTolerance,
            _swapTolerance,
            _receiver
        );

        // determine amount of synthetix perp position debt to unwind
        uint256 debt = _approximateLoanNeeded(_accountId);

        IPool(AAVE).flashLoanSimple({
            receiverAddress: address(this),
            asset: USDC,
            amount: debt,
            params: params,
            referralCode: REFERRAL_CODE
        });

        stage = Stage.UNSET;
    }

    /// @notice flashloan callback function
    /// @dev caller must be the Aave lending pool
    /// @custom:caution calling this function directly is not recommended
    /// @param _flashloan amount of USDC flashloaned from Aave
    /// @param _premium amount of USDC premium owed to Aave
    /// @param _params encoded parameters for unwinding synthetix perp position
    /// @return bool representing successful execution
    function executeOperation(
        address,
        uint256 _flashloan,
        uint256 _premium,
        address,
        bytes calldata _params
    ) external onlyAave requireStage(Stage.LEVEL1) returns (bool) {
        stage = Stage.LEVEL2;

        (,,, address _collateral,,,, address _receiver) = abi.decode(
            _params,
            (
                uint128,
                uint128,
                uint256,
                address,
                uint256,
                uint256,
                uint256,
                address
            )
        );

        uint256 unwound = _unwind(_flashloan, _premium, _params);

        _push(_collateral, _receiver, unwound);

        return IERC20(USDC).approve(AAVE, _flashloan + _premium);
    }

    /// @dev unwinds synthetix perp position collateral
    /// @param _flashloan amount of USDC flashloaned from Aave
    /// @param _premium amount of USDC premium owed to Aave
    /// @param _params encoded parameters for unwinding synthetix perp position
    /// @return unwound amount of collateral
    function _unwind(
        uint256 _flashloan,
        uint256 _premium,
        bytes calldata _params
    ) internal requireStage(Stage.LEVEL2) returns (uint256 unwound) {
        (
            uint128 _accountId,
            uint128 _collateralId,
            uint256 _collateralAmount,
            address _collateral,
            uint256 _zapTolerance,
            uint256 _unwrapTolerance,
            uint256 _swapTolerance,
            /* address _receiver */
        ) = abi.decode(
            _params,
            (
                uint128,
                uint128,
                uint256,
                address,
                uint256,
                uint256,
                uint256,
                address
            )
        );

        // zap USDC from flashloan into USDx
        uint256 usdxAmount = _zapIn(_flashloan, _zapTolerance);

        // burn USDx to pay off synthetix perp position debt;
        // debt is denominated in USD and thus repaid with USDx
        _burn(usdxAmount, _accountId);

        // withdraw synthetix perp position collateral to this contract;
        // i.e., # of sETH, # of sUSDe, # of sUSDC (...)
        _withdraw(_collateralId, _collateralAmount, _accountId);

        // unwrap withdrawn synthetix perp position collateral;
        // i.e., sETH -> WETH, sUSDe -> USDe, sUSDC -> USDC (...)
        unwound = _unwrap(_collateralId, _collateralAmount, _unwrapTolerance);

        // establish total debt now owed to Aave;
        // i.e., # of USDC
        _flashloan += _premium;

        // swap as much (or little) as necessary to repay Aave flashloan;
        // i.e., WETH -(swap)-> USDC -(repay)-> Aave
        // i.e., USDe -(swap)-> USDC -(repay)-> Aave
        // i.e., USDC -(repay)-> Aave
        // whatever collateral amount is remaining is returned to the caller
        unwound -= _collateral == USDC
            ? _flashloan
            : _swapFor(_collateral, _flashloan, _swapTolerance);
    }

    /// @notice approximate USDC needed to unwind synthetix perp position
    /// @param _accountId synthetix perp market account id
    /// @return amount of USDC needed
    function _approximateLoanNeeded(uint128 _accountId)
        internal
        view
        returns (uint256 amount)
    {
        // determine amount of debt associated with synthetix perp position
        amount = IPerpsMarket(PERPS_MARKET).debt(_accountId);

        uint256 usdxDecimals = IERC20(USDX).decimals();
        uint256 usdcDecimals = IERC20(USDC).decimals();

        /// @custom:synthetix debt is denominated in USDx
        /// @custom:aave debt is denominated in USDC
        /// @dev scale loan amount accordingly
        amount /= 10 ** (usdxDecimals - usdcDecimals);

        /// @dev barring exceptional circumstances,
        /// a 1 USD buffer is sufficient to circumvent
        /// precision loss
        amount += 10 ** usdcDecimals;
    }

    /*//////////////////////////////////////////////////////////////
                                  BURN
    //////////////////////////////////////////////////////////////*/

    /// @notice burn USDx to pay off synthetix perp position debt
    /// @custom:caution ALL USDx remaining post-burn will be sent to the caller
    /// @dev caller must grant USDX allowance to this contract
    /// @dev excess USDx will be returned to the caller
    /// @param _amount amount of USDx to burn
    /// @param _accountId synthetix perp market account id
    function burn(uint256 _amount, uint128 _accountId) external {
        _pull(USDX, msg.sender, _amount);
        _burn(_amount, _accountId);
        uint256 remaining = IERC20(USDX).balanceOf(address(this));
        if (remaining > 0) _push(USDX, msg.sender, remaining);
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold any excess USDx
    function _burn(uint256 _amount, uint128 _accountId) internal {
        IERC20(USDX).approve(PERPS_MARKET, _amount);
        IPerpsMarket(PERPS_MARKET).payDebt(_accountId, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/

    /// @notice withdraw collateral from synthetix perp position
    /// @custom:synthetix RBAC permission required: "PERPS_MODIFY_COLLATERAL"
    /// @param _synthId synthetix market id of collateral
    /// @param _amount amount of collateral to withdraw
    /// @param _accountId synthetix perp market account id
    /// @param _receiver address to receive collateral
    function withdraw(
        uint128 _synthId,
        uint256 _amount,
        uint128 _accountId,
        address _receiver
    ) external isAuthorized(_accountId) {
        _withdraw(_synthId, _amount, _accountId);
        address synth = _synthId == USDX_ID
            ? USDX
            : ISpotMarket(SPOT_MARKET).getSynth(_synthId);
        _push(synth, _receiver, _amount);
    }

    /// @custom:synthetix RBAC permission required: "PERPS_MODIFY_COLLATERAL"
    /// @dev following execution, this contract will hold the withdrawn
    /// collateral
    function _withdraw(uint128 _synthId, uint256 _amount, uint128 _accountId)
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

    /// @notice query amount required to receive a specific amount of token
    /// @dev quoting is NOT gas efficient and should NOT be called on chain
    /// @custom:integrator quoting function inclusion is for QoL purposes
    /// @param _tokenIn address of token being swapped in
    /// @param _tokenOut address of token being swapped out
    /// @param _amountOut is the desired output amount
    /// @param _fee of the token pool to consider for the pair
    /// @param _sqrtPriceLimitX96 of the pool; cannot be exceeded for swap
    /// @return amountIn required as the input for the swap in order
    /// @return sqrtPriceX96After of the pool after the swap
    /// @return initializedTicksCrossed during the quoted swap
    /// @return gasEstimate of gas that the swap will consume
    function quoteSwapFor(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut,
        uint24 _fee,
        uint160 _sqrtPriceLimitX96
    )
        external
        returns (
            uint256 amountIn,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        )
    {
        return IQuoter(QUOTER).quoteExactOutputSingle(
            IQuoter.QuoteExactOutputSingleParams(
                _tokenIn, _tokenOut, _amountOut, _fee, _sqrtPriceLimitX96
            )
        );
    }

    /// @notice query amount received for a specific amount of token to spend
    /// @dev quoting is NOT gas efficient and should NOT be called on chain
    /// @custom:integrator quoting function inclusion is for QoL purposes
    /// @param _tokenIn address of token being swapped in
    /// @param _tokenOut address of token being swapped out
    /// @param _amountIn is the input amount to spend
    /// @param _fee of the token pool to consider for the pair
    /// @param _sqrtPriceLimitX96 of the pool; cannot be exceeded for swap
    /// @return amountOut received as the output for the swap in order
    /// @return sqrtPriceX96After of the pool after the swap
    /// @return initializedTicksCrossed during the quoted swap
    /// @return gasEstimate of gas that the swap will consume
    function quoteSwapWith(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint24 _fee,
        uint160 _sqrtPriceLimitX96
    )
        external
        returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        )
    {
        return IQuoter(QUOTER).quoteExactInputSingle(
            IQuoter.QuoteExactInputSingleParams(
                _tokenIn, _tokenOut, _amountIn, _fee, _sqrtPriceLimitX96
            )
        );
    }

    /// @notice swap a tolerable amount of tokens for a specific amount of USDC
    /// @dev caller must grant token allowance to this contract
    /// @dev any excess token not spent will be returned to the caller
    /// @param _from address of token to swap
    /// @param _amount amount of USDC to receive in return
    /// @param _tolerance or tolerable amount of token to spend
    /// @param _receiver address to receive USDC
    /// @return deducted amount of incoming token; i.e., amount spent
    function swapFor(
        address _from,
        uint256 _amount,
        uint256 _tolerance,
        address _receiver
    ) external returns (uint256 deducted) {
        _pull(_from, msg.sender, _tolerance);
        deducted = _swapFor(_from, _amount, _tolerance);
        _push(USDC, _receiver, _amount);

        if (deducted < _tolerance) {
            _push(_from, msg.sender, _tolerance - deducted);
        }
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold the swapped USDC
    function _swapFor(address _from, uint256 _amount, uint256 _tolerance)
        internal
        returns (uint256 deducted)
    {
        IERC20(_from).approve(ROUTER, _tolerance);

        IRouter.ExactOutputSingleParams memory params = IRouter
            .ExactOutputSingleParams({
            tokenIn: _from,
            tokenOut: USDC,
            fee: FEE_TIER,
            recipient: address(this),
            amountOut: _amount,
            amountInMaximum: _tolerance,
            sqrtPriceLimitX96: 0
        });

        try IRouter(ROUTER).exactOutputSingle(params) returns (uint256 amountIn)
        {
            deducted = amountIn;
        } catch Error(string memory reason) {
            revert SwapFailed(reason);
        }
    }

    /// @notice swap a specific amount of tokens for a tolerable amount of USDC
    /// @dev caller must grant token allowance to this contract
    /// @param _from address of token to swap
    /// @param _amount of token to swap
    /// @param _tolerance tolerable amount of USDC to receive specified with 6
    /// decimals
    /// @param _receiver address to receive USDC
    /// @return received amount of USDC
    function swapWith(
        address _from,
        uint256 _amount,
        uint256 _tolerance,
        address _receiver
    ) external returns (uint256 received) {
        _pull(_from, msg.sender, _amount);
        received = _swapWith(_from, _amount, _tolerance);
        _push(USDC, _receiver, received);
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold the swapped USDC
    function _swapWith(address _from, uint256 _amount, uint256 _tolerance)
        internal
        returns (uint256 received)
    {
        IERC20(_from).approve(ROUTER, _amount);

        IRouter.ExactInputSingleParams memory params = IRouter
            .ExactInputSingleParams({
            tokenIn: _from,
            tokenOut: USDC,
            fee: FEE_TIER,
            recipient: address(this),
            amountIn: _amount,
            amountOutMinimum: _tolerance,
            sqrtPriceLimitX96: 0
        });

        try IRouter(ROUTER).exactInputSingle(params) returns (uint256 amountOut)
        {
            received = amountOut;
        } catch Error(string memory reason) {
            revert SwapFailed(reason);
        }
    }

    /*//////////////////////////////////////////////////////////////
                               TRANSFERS
    //////////////////////////////////////////////////////////////*/

    /// @dev pull tokens from a sender
    /// @param _token address of token to pull
    /// @param _from address of sender
    /// @param _amount amount of token to pull
    /// @return success boolean representing execution success
    function _pull(address _token, address _from, uint256 _amount)
        internal
        returns (bool success)
    {
        IERC20 token = IERC20(_token);

        try token.transferFrom(_from, address(this), _amount) returns (
            bool result
        ) {
            success = result;
            require(
                success,
                PullFailed(abi.encodePacked(address(token), _from, _amount))
            );
        } catch Error(string memory reason) {
            revert PullFailed(bytes(reason));
        }
    }

    /// @dev push tokens to a receiver
    /// @param _token address of token to push
    /// @param _receiver address of receiver
    /// @param _amount amount of token to push
    /// @return success boolean representing execution success
    function _push(address _token, address _receiver, uint256 _amount)
        internal
        returns (bool success)
    {
        IERC20 token = IERC20(_token);

        try token.transfer(_receiver, _amount) returns (bool result) {
            success = result;
            require(
                success,
                PushFailed(abi.encodePacked(address(token), _receiver, _amount))
            );
        } catch Error(string memory reason) {
            revert PushFailed(bytes(reason));
        }
    }
}

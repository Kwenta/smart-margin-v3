// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IPool} from "./interfaces/IAave.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IPerpsMarket, ISpotMarket} from "./interfaces/ISynthetix.sol";
import {IQuoter, IRouter} from "./interfaces/IUniswap.sol";
import {Errors} from "./utils/Errors.sol";
import {Reentrancy} from "./utils/Reentrancy.sol";
import {SafeERC20} from "./utils/SafeTransferERC20.sol";

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
    bytes32 public constant MODIFY_PERMISSION = "PERPS_MODIFY_COLLATERAL";
    bytes32 public constant BURN_PERMISSION = "BURN";
    uint128 public immutable USDX_ID;
    address public immutable USDX;
    address public immutable SPOT_MARKET;
    address public immutable PERPS_MARKET;
    address public immutable REFERRER;
    uint128 public immutable SUSDC_SPOT_ID;

    /// @custom:aave
    uint16 public constant REFERRAL_CODE = 0;
    address public immutable AAVE;

    /// @custom:uniswap
    uint24 public constant FEE_TIER = 3000;
    address public immutable ROUTER;
    address public immutable QUOTER;

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

        /// @custom:aave
        AAVE = _aave;

        /// @custom:uniswap
        ROUTER = _router;
        QUOTER = _quoter;
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
    /// @param _minAmountOut acceptable slippage for wrapping and selling
    /// @param _receiver address to receive USDx
    /// @return zapped amount of USDx received
    function zapIn(uint256 _amount, uint256 _minAmountOut, address _receiver)
        external
        returns (uint256 zapped)
    {
        _pull(USDC, msg.sender, _amount);
        zapped = _zapIn(_amount, _minAmountOut);
        _push(USDX, _receiver, zapped);
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold the zapped USDx
    function _zapIn(uint256 _amount, uint256 _minAmountOut)
        internal
        returns (uint256 zapped)
    {
        zapped = _wrap(USDC, SUSDC_SPOT_ID, _amount, _minAmountOut);
        zapped = _sell(SUSDC_SPOT_ID, zapped, _minAmountOut);
    }

    /// @notice zap USDx into USDC
    /// @dev caller must grant USDx allowance to this contract
    /// @param _amount amount of USDx to zap
    /// @param _minAmountOut acceptable slippage for buying and unwrapping
    /// @param _receiver address to receive USDC
    /// @return zapped amount of USDC received
    function zapOut(uint256 _amount, uint256 _minAmountOut, address _receiver)
        external
        returns (uint256 zapped)
    {
        _pull(USDX, msg.sender, _amount);
        zapped = _zapOut(_amount, _minAmountOut);
        _push(USDC, _receiver, zapped);
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold the zapped USDC
    function _zapOut(uint256 _amount, uint256 _minAmountOut)
        internal
        returns (uint256 zapped)
    {
        zapped = _buy(SUSDC_SPOT_ID, _amount, _minAmountOut);
        zapped = _unwrap(SUSDC_SPOT_ID, zapped, _minAmountOut);
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
    /// @param _minAmountOut acceptable slippage for wrapping
    /// @param _receiver address to receive wrapped synth
    /// @return wrapped amount of synth received
    function wrap(
        address _token,
        uint128 _synthId,
        uint256 _amount,
        uint256 _minAmountOut,
        address _receiver
    ) external returns (uint256 wrapped) {
        _pull(_token, msg.sender, _amount);
        wrapped = _wrap(_token, _synthId, _amount, _minAmountOut);
        _push(ISpotMarket(SPOT_MARKET).getSynth(_synthId), _receiver, wrapped);
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold the wrapped synth
    function _wrap(
        address _token,
        uint128 _synthId,
        uint256 _amount,
        uint256 _minAmountOut
    ) internal returns (uint256 wrapped) {
        IERC20(_token).approve(SPOT_MARKET, _amount);
        (wrapped,) = ISpotMarket(SPOT_MARKET).wrap({
            marketId: _synthId,
            wrapAmount: _amount,
            minAmountReceived: _minAmountOut
        });
    }

    /// @notice unwrap collateral via synthetix spot market
    /// @dev caller must grant synth allowance to this contract
    /// @custom:synth -> synthetix token representation of wrapped collateral
    /// @param _token address of token to unwrap into
    /// @param _synthId synthetix market id of synth to unwrap
    /// @param _amount amount of synth to unwrap
    /// @param _minAmountOut acceptable slippage for unwrapping
    /// @param _receiver address to receive unwrapped token
    /// @return unwrapped amount of token received
    function unwrap(
        address _token,
        uint128 _synthId,
        uint256 _amount,
        uint256 _minAmountOut,
        address _receiver
    ) external returns (uint256 unwrapped) {
        address synth = ISpotMarket(SPOT_MARKET).getSynth(_synthId);
        _pull(synth, msg.sender, _amount);
        unwrapped = _unwrap(_synthId, _amount, _minAmountOut);
        _push(_token, _receiver, unwrapped);
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold the unwrapped token
    function _unwrap(uint128 _synthId, uint256 _amount, uint256 _minAmountOut)
        private
        returns (uint256 unwrapped)
    {
        address synth = ISpotMarket(SPOT_MARKET).getSynth(_synthId);
        IERC20(synth).approve(SPOT_MARKET, _amount);
        (unwrapped,) = ISpotMarket(SPOT_MARKET).unwrap({
            marketId: _synthId,
            unwrapAmount: _amount,
            minAmountReceived: _minAmountOut
        });
    }

    /*//////////////////////////////////////////////////////////////
                              BUY AND SELL
    //////////////////////////////////////////////////////////////*/

    /// @notice buy synth via synthetix spot market
    /// @dev caller must grant USDX allowance to this contract
    /// @param _synthId synthetix market id of synth to buy
    /// @param _amount amount of USDX to spend
    /// @param _minAmountOut acceptable slippage for buying
    /// @param _receiver address to receive synth
    /// @return received amount of synth
    function buy(
        uint128 _synthId,
        uint256 _amount,
        uint256 _minAmountOut,
        address _receiver
    ) external returns (uint256 received, address synth) {
        synth = ISpotMarket(SPOT_MARKET).getSynth(_synthId);
        _pull(USDX, msg.sender, _amount);
        received = _buy(_synthId, _amount, _minAmountOut);
        _push(synth, _receiver, received);
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold the bought synth
    function _buy(uint128 _synthId, uint256 _amount, uint256 _minAmountOut)
        internal
        returns (uint256 received)
    {
        IERC20(USDX).approve(SPOT_MARKET, _amount);
        (received,) = ISpotMarket(SPOT_MARKET).buy({
            marketId: _synthId,
            usdAmount: _amount,
            minAmountReceived: _minAmountOut,
            referrer: REFERRER
        });
    }

    /// @notice sell synth via synthetix spot market
    /// @dev caller must grant synth allowance to this contract
    /// @param _synthId synthetix market id of synth to sell
    /// @param _amount amount of synth to sell
    /// @param _minAmountOut acceptable slippage for selling
    /// @param _receiver address to receive USDX
    /// @return received amount of USDX
    function sell(
        uint128 _synthId,
        uint256 _amount,
        uint256 _minAmountOut,
        address _receiver
    ) external returns (uint256 received) {
        address synth = ISpotMarket(SPOT_MARKET).getSynth(_synthId);
        _pull(synth, msg.sender, _amount);
        received = _sell(_synthId, _amount, _minAmountOut);
        _push(USDX, _receiver, received);
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold the sold USDX
    function _sell(uint128 _synthId, uint256 _amount, uint256 _minAmountOut)
        internal
        returns (uint256 received)
    {
        address synth = ISpotMarket(SPOT_MARKET).getSynth(_synthId);
        IERC20(synth).approve(SPOT_MARKET, _amount);
        (received,) = ISpotMarket(SPOT_MARKET).sell({
            marketId: _synthId,
            synthAmount: _amount,
            minUsdAmount: _minAmountOut,
            referrer: REFERRER
        });
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
    /// @param _path Uniswap swap path encoded in reverse order
    /// @param _zapMinAmountOut acceptable slippage for zapping
    /// @param _unwrapMinAmountOut acceptable slippage for unwrapping
    /// @param _swapMaxAmountIn acceptable slippage for swapping
    /// @param _receiver address to receive unwound collateral
    function unwind(
        uint128 _accountId,
        uint128 _collateralId,
        uint256 _collateralAmount,
        address _collateral,
        bytes memory _path,
        uint256 _zapMinAmountOut,
        uint256 _unwrapMinAmountOut,
        uint256 _swapMaxAmountIn,
        address _receiver
    ) external isAuthorized(_accountId) requireStage(Stage.UNSET) {
        stage = Stage.LEVEL1;

        bytes memory params = abi.encode(
            _accountId,
            _collateralId,
            _collateralAmount,
            _collateral,
            _path,
            _zapMinAmountOut,
            _unwrapMinAmountOut,
            _swapMaxAmountIn,
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

        (,,, address _collateral,,,,, address _receiver) = abi.decode(
            _params,
            (
                uint128,
                uint128,
                uint256,
                address,
                bytes,
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
        {
            (
                uint128 _accountId,
                uint128 _collateralId,
                uint256 _collateralAmount,
                ,
                ,
                uint256 _zapMinAmountOut,
                uint256 _unwrapMinAmountOut,
                ,
            ) = abi.decode(
                _params,
                (
                    uint128,
                    uint128,
                    uint256,
                    address,
                    bytes,
                    uint256,
                    uint256,
                    uint256,
                    address
                )
            );

            // zap USDC from flashloan into USDx;
            // ALL USDC flashloaned from Aave is zapped into USDx
            uint256 usdxAmount = _zapIn(_flashloan, _zapMinAmountOut);

            // burn USDx to pay off synthetix perp position debt;
            // debt is denominated in USD and thus repaid with USDx
            _burn(usdxAmount, _accountId);

            /// @dev given the USDC buffer, an amount of USDx
            /// necessarily less than the buffer will remain (<$1);
            /// this amount is captured by the protocol
            // withdraw synthetix perp position collateral to this contract;
            // i.e., # of sETH, # of sUSDe, # of sUSDC (...)
            _withdraw(_collateralId, _collateralAmount, _accountId);

            // unwrap withdrawn synthetix perp position collateral;
            // i.e., sETH -> WETH, sUSDe -> USDe, sUSDC -> USDC (...)
            unwound =
                _unwrap(_collateralId, _collateralAmount, _unwrapMinAmountOut);

            // establish total debt now owed to Aave;
            // i.e., # of USDC
            _flashloan += _premium;
        }

        (
            ,
            ,
            ,
            address _collateral,
            bytes memory _path,
            ,
            ,
            uint256 _swapMaxAmountIn,
        ) = abi.decode(
            _params,
            (
                uint128,
                uint128,
                uint256,
                address,
                bytes,
                uint256,
                uint256,
                uint256,
                address
            )
        );

        // swap as much (or little) as necessary to repay Aave flashloan;
        // i.e., WETH -(swap)-> USDC -(repay)-> Aave
        // i.e., USDe -(swap)-> USDC -(repay)-> Aave
        // i.e., USDC -(repay)-> Aave
        // whatever collateral amount is remaining is returned to the caller
        unwound -= _collateral == USDC
            ? _flashloan
            : _swapFor(_collateral, _path, _flashloan, _swapMaxAmountIn);
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
    /// @return remaining amount of USDx returned to the caller
    function burn(uint256 _amount, uint128 _accountId)
        external
        returns (uint256 remaining)
    {
        _pull(USDX, msg.sender, _amount);
        _burn(_amount, _accountId);
        remaining = IERC20(USDX).balanceOf(address(this));
        if (remaining > 0) _push(USDX, msg.sender, remaining);
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold any excess USDx
    function _burn(uint256 _amount, uint128 _accountId) internal {
        IERC20(USDX).approve(PERPS_MARKET, _amount);
        IPerpsMarket(PERPS_MARKET).payDebt(_accountId, _amount);
        IERC20(USDX).approve(PERPS_MARKET, 0);
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
    /// @dev this is the QuoterV1 interface
    /// @dev _path MUST be encoded backwards for `exactOutput`
    /// @dev quoting is NOT gas efficient and should NOT be called on chain
    /// @custom:integrator quoting function inclusion is for QoL purposes
    /// @param _path Uniswap swap path encoded in reverse order
    /// @param _amountOut is the desired output amount
    /// @return amountIn required as the input for the swap in order
    function quoteSwapFor(bytes memory _path, uint256 _amountOut)
        external
        returns (
            uint256 amountIn,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        )
    {
        return IQuoter(QUOTER).quoteExactOutput(_path, _amountOut);
    }

    /// @notice query amount received for a specific amount of token to spend
    /// @dev this is the QuoterV1 interface
    /// @dev _path MUST be encoded in order for `exactInput`
    /// @dev quoting is NOT gas efficient and should NOT be called on chain
    /// @custom:integrator quoting function inclusion is for QoL purposes
    /// @param _path Uniswap swap path encoded in order
    /// @param _amountIn is the input amount to spendp
    /// @return amountOut received as the output for the swap in order
    function quoteSwapWith(bytes memory _path, uint256 _amountIn)
        external
        returns (
            uint256 amountOut,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        )
    {
        return IQuoter(QUOTER).quoteExactInput(_path, _amountIn);
    }

    /// @notice swap a tolerable amount of tokens for a specific amount of USDC
    /// @dev _path MUST be encoded backwards for `exactOutput`
    /// @dev caller must grant token allowance to this contract
    /// @dev any excess token not spent will be returned to the caller
    /// @param _from address of token to swap
    /// @param _path uniswap swap path encoded in reverse order
    /// @param _amount amount of USDC to receive in return
    /// @param _maxAmountIn max amount of token to spend
    /// @param _receiver address to receive USDC
    /// @return deducted amount of incoming token; i.e., amount spent
    function swapFor(
        address _from,
        bytes memory _path,
        uint256 _amount,
        uint256 _maxAmountIn,
        address _receiver
    ) external returns (uint256 deducted) {
        _pull(_from, msg.sender, _maxAmountIn);
        deducted = _swapFor(_from, _path, _amount, _maxAmountIn);
        _push(USDC, _receiver, _amount);

        if (deducted < _maxAmountIn) {
            _push(_from, msg.sender, _maxAmountIn - deducted);
        }
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold the swapped USDC
    function _swapFor(
        address _from,
        bytes memory _path,
        uint256 _amount,
        uint256 _maxAmountIn
    ) internal returns (uint256 deducted) {
        IERC20(_from).approve(ROUTER, _maxAmountIn);

        IRouter.ExactOutputParams memory params = IRouter.ExactOutputParams({
            path: _path,
            recipient: address(this),
            amountOut: _amount,
            amountInMaximum: _maxAmountIn
        });

        try IRouter(ROUTER).exactOutput(params) returns (uint256 amountIn) {
            deducted = amountIn;
        } catch Error(string memory reason) {
            revert SwapFailed(reason);
        }

        IERC20(_from).approve(ROUTER, 0);
    }

    /// @notice swap a specific amount of tokens for a tolerable amount of USDC
    /// @dev _path MUST be encoded in order for `exactInput`
    /// @dev caller must grant token allowance to this contract
    /// @param _from address of token to swap
    /// @param _path uniswap swap path encoded in order
    /// @param _amount of token to swap
    /// @param _amountOutMinimum tolerable amount of USDC to receive specified
    /// with 6
    /// decimals
    /// @param _receiver address to receive USDC
    /// @return received amount of USDC
    function swapWith(
        address _from,
        bytes memory _path,
        uint256 _amount,
        uint256 _amountOutMinimum,
        address _receiver
    ) external returns (uint256 received) {
        _pull(_from, msg.sender, _amount);
        received = _swapWith(_from, _path, _amount, _amountOutMinimum);
        _push(USDC, _receiver, received);
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold the swapped USDC
    function _swapWith(
        address _from,
        bytes memory _path,
        uint256 _amount,
        uint256 _amountOutMinimum
    ) internal returns (uint256 received) {
        IERC20(_from).approve(ROUTER, _amount);

        IRouter.ExactInputParams memory params = IRouter.ExactInputParams({
            path: _path,
            recipient: address(this),
            amountIn: _amount,
            amountOutMinimum: _amountOutMinimum
        });

        try IRouter(ROUTER).exactInput(params) returns (uint256 amountOut) {
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
    function _pull(address _token, address _from, uint256 _amount) internal {
        require(_amount > 0, PullFailed("Zero Amount"));
        IERC20 token = IERC20(_token);

        SafeERC20.safeTransferFrom(token, _from, address(this), _amount);
    }

    /// @dev push tokens to a receiver
    /// @param _token address of token to push
    /// @param _receiver address of receiver
    /// @param _amount amount of token to push
    function _push(address _token, address _receiver, uint256 _amount)
        internal
    {
        require(_receiver != address(0), PushFailed("Zero Address"));
        require(_amount > 0, PushFailed("Zero Amount"));
        IERC20 token = IERC20(_token);

        SafeERC20.safeTransfer(token, _receiver, _amount);
    }
}

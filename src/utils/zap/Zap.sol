// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IPool} from "./interfaces/IAave.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IPerpsMarket, ISpotMarket} from "./interfaces/ISynthetix.sol";
import {Errors} from "./utils/Errors.sol";

import {Flush} from "./utils/Flush.sol";
import {Reentrancy} from "./utils/Reentrancy.sol";
import {SafeERC20} from "./utils/SafeTransferERC20.sol";

/// @title zap
/// @custom:synthetix zap USDC into and out of USDx
/// @custom:aave flash loan USDC to unwind synthetix collateral
/// @custom:odos swap unwound collateral for USDC to repay flashloan
/// @dev idle token balances are not safe
/// @dev intended for standalone use; do not inherit
/// @author @jaredborders
/// @author @flocqst
/// @author @barrasso
/// @author @moss-eth
contract Zap is Reentrancy, Errors, Flush(msg.sender) {

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

    /// @custom:odos
    address public immutable ROUTER;

    constructor(
        address _usdc,
        address _usdx,
        address _spotMarket,
        address _perpsMarket,
        address _referrer,
        uint128 _susdcSpotId,
        address _aave,
        address _router
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

        /// @custom:odos
        ROUTER = _router;
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
    function zapIn(
        uint256 _amount,
        uint256 _minAmountOut,
        address _receiver
    )
        external
        returns (uint256 zapped)
    {
        _pull(USDC, msg.sender, _amount);
        zapped = _zapIn(_amount, _minAmountOut);
        _push(USDX, _receiver, zapped);
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold the zapped USDx
    function _zapIn(
        uint256 _amount,
        uint256 _minAmountOut
    )
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
    function zapOut(
        uint256 _amount,
        uint256 _minAmountOut,
        address _receiver
    )
        external
        returns (uint256 zapped)
    {
        _pull(USDX, msg.sender, _amount);
        zapped = _zapOut(_amount, _minAmountOut);
        _push(USDC, _receiver, zapped);
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold the zapped USDC
    function _zapOut(
        uint256 _amount,
        uint256 _minAmountOut
    )
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
    /// @custom:synth -> synthetix token representation of an asset with an
    /// acceptable onchain price oracle
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
    )
        external
        returns (uint256 wrapped)
    {
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
    )
        internal
        returns (uint256 wrapped)
    {
        IERC20(_token).approve(SPOT_MARKET, _amount);
        (wrapped,) = ISpotMarket(SPOT_MARKET).wrap({
            marketId: _synthId,
            wrapAmount: _amount,
            minAmountReceived: _minAmountOut
        });
    }

    /// @notice unwrap collateral via synthetix spot market
    /// @dev caller must grant synth allowance to this contract
    /// @custom:synth -> synthetix token representation of an asset with an
    /// acceptable onchain price oracle
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
    )
        external
        returns (uint256 unwrapped)
    {
        address synth = ISpotMarket(SPOT_MARKET).getSynth(_synthId);
        _pull(synth, msg.sender, _amount);
        unwrapped = _unwrap(_synthId, _amount, _minAmountOut);
        _push(_token, _receiver, unwrapped);
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold the unwrapped token
    function _unwrap(
        uint128 _synthId,
        uint256 _amount,
        uint256 _minAmountOut
    )
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
    )
        external
        returns (uint256 received, address synth)
    {
        synth = ISpotMarket(SPOT_MARKET).getSynth(_synthId);
        _pull(USDX, msg.sender, _amount);
        received = _buy(_synthId, _amount, _minAmountOut);
        _push(synth, _receiver, received);
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold the bought synth
    function _buy(
        uint128 _synthId,
        uint256 _amount,
        uint256 _minAmountOut
    )
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
    )
        external
        returns (uint256 received)
    {
        address synth = ISpotMarket(SPOT_MARKET).getSynth(_synthId);
        _pull(synth, msg.sender, _amount);
        received = _sell(_synthId, _amount, _minAmountOut);
        _push(USDX, _receiver, received);
    }

    /// @dev allowance is assumed
    /// @dev following execution, this contract will hold the sold USDX
    function _sell(
        uint128 _synthId,
        uint256 _amount,
        uint256 _minAmountOut
    )
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
    /// @custom:synthetix RBAC permission required: "PERPS_MODIFY_COLLATERAL"
    /// @param _accountId synthetix perp market account id
    /// @param _collateralId synthetix spot market id or synth id
    /// @param _collateralAmount amount of collateral to unwind
    /// @param _collateral address of collateral to unwind
    /// @param _path odos path from the sor/assemble api endpoint
    /// @param _zapMinAmountOut acceptable slippage for zapping
    /// @param _unwrapMinAmountOut acceptable slippage for unwrapping
    /// @param _swapAmountIn amount intended to be swapped by odos
    /// @param _receiver address to receive unwound collateral
    function unwind(
        uint128 _accountId,
        uint128 _collateralId,
        uint256 _collateralAmount,
        address _collateral,
        bytes memory _path,
        uint256 _zapMinAmountOut,
        uint256 _unwrapMinAmountOut,
        uint256 _swapAmountIn,
        address _receiver
    )
        external
        isAuthorized(_accountId)
        requireStage(Stage.UNSET)
    {
        stage = Stage.LEVEL1;

        bytes memory params = abi.encode(
            _accountId,
            _collateralId,
            _collateralAmount,
            _collateral,
            _path,
            _zapMinAmountOut,
            _unwrapMinAmountOut,
            _swapAmountIn,
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
    )
        external
        onlyAave
        requireStage(Stage.LEVEL1)
        returns (bool)
    {
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

        if (unwound > 0) _push(_collateral, _receiver, unwound);

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
    )
        internal
        requireStage(Stage.LEVEL2)
        returns (uint256 unwound)
    {
        (
            uint128 _accountId,
            uint128 _collateralId,
            uint256 _collateralAmount,
            address _collateral,
            bytes memory _path,
            uint256 _zapMinAmountOut,
            uint256 _unwrapMinAmountOut,
            uint256 _swapAmountIn,
            address _receiver
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

        if (_collateral == USDC && _collateralId == USDX_ID) {
            unwound = _zapOut(_collateralAmount, _collateralAmount / 1e12);
        } else {
            // unwrap withdrawn synthetix perp position collateral;
            // i.e., sETH -> WETH, sUSDe -> USDe, sUSDC -> USDC (...)
            unwound =
                _unwrap(_collateralId, _collateralAmount, _unwrapMinAmountOut);
        }

        // establish total debt now owed to Aave;
        // i.e., # of USDC
        _flashloan += _premium;

        // swap as much (or little) as necessary to repay Aave flashloan;
        // i.e., WETH -(swap)-> USDC -(repay)-> Aave
        // i.e., USDe -(swap)-> USDC -(repay)-> Aave
        // i.e., USDC -(repay)-> Aave
        // whatever collateral amount is remaining is returned to the caller
        if (_collateral == USDC) {
            unwound -= _flashloan;
        } else {
            odosSwap(_collateral, _swapAmountIn, _path);
            unwound -= _swapAmountIn;
            uint256 leftovers = IERC20(USDC).balanceOf(address(this));
            if (leftovers > _flashloan) {
                _push(USDC, _receiver, leftovers - _flashloan);
            }
        }

        /// @notice the path and max amount in must take into consideration:
        ///     (1) Aave flashloan amount
        ///     (2) premium owed to Aave for flashloan
        ///     (3) USDC buffer added to the approximate loan needed
        ///
        /// @dev (1) is a function of (3); buffer added to loan requested
        /// @dev (2) is a function of (1); premium is a percentage of loan
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
    /// @return excess amount of USDx returned to the caller
    function burn(
        uint256 _amount,
        uint128 _accountId
    )
        external
        returns (uint256 excess)
    {
        excess = IERC20(USDX).balanceOf(address(this));

        // pull and burn
        _pull(USDX, msg.sender, _amount);
        _burn(_amount, _accountId);

        excess = IERC20(USDX).balanceOf(address(this)) - excess;

        if (excess > 0) _push(USDX, msg.sender, excess);
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
    )
        external
        isAuthorized(_accountId)
    {
        _withdraw(_synthId, _amount, _accountId);
        address synth = _synthId == USDX_ID
            ? USDX
            : ISpotMarket(SPOT_MARKET).getSynth(_synthId);
        _push(synth, _receiver, _amount);
    }

    /// @custom:synthetix RBAC permission required: "PERPS_MODIFY_COLLATERAL"
    /// @dev following execution, this contract will hold the withdrawn
    /// collateral
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
                                ODOS
    //////////////////////////////////////////////////////////////*/

    /// @notice swap the input amount of tokens for USDC using Odos
    /// @dev _path USDC is not enforced as the output token during the swap, but
    /// is expected in the call to push
    /// @dev caller must grant token allowance to this contract
    /// @param _from address of token to swap
    /// @param _path odos path from the sor/assemble api endpoint
    /// @param _amountIn amount of token to spend
    /// @param _receiver address to receive USDC
    /// @return amountOut amount of tokens swapped for
    function swapFrom(
        address _from,
        bytes memory _path,
        uint256 _amountIn,
        address _receiver
    )
        external
        returns (uint256 amountOut)
    {
        _pull(_from, msg.sender, _amountIn);
        amountOut = odosSwap(_from, _amountIn, _path);
        _push(USDC, _receiver, amountOut);

        // refund if there is any amount of `_from` token left
        uint256 amountLeft = IERC20(_from).balanceOf(address(this));
        if (amountLeft > 0) _push(_from, msg.sender, amountLeft);
    }

    /// @dev following execution, this contract will hold the swapped USDC
    /// @param _tokenFrom address of token being swapped
    /// @param _amountIn amount of token being swapped
    /// @param _swapPath bytes from odos assemble api containing the swap
    /// details
    function odosSwap(
        address _tokenFrom,
        uint256 _amountIn,
        bytes memory _swapPath
    )
        internal
        returns (uint256 amountOut)
    {
        IERC20(_tokenFrom).approve(ROUTER, _amountIn);

        (bool success, bytes memory result) = ROUTER.call{value: 0}(_swapPath);
        require(success, SwapFailed());
        amountOut = abi.decode(result, (uint256));

        IERC20(_tokenFrom).approve(ROUTER, 0);
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
    function _push(
        address _token,
        address _receiver,
        uint256 _amount
    )
        internal
    {
        require(_receiver != address(0), PushFailed("Zero Address"));
        require(_amount > 0, PushFailed("Zero Amount"));
        IERC20 token = IERC20(_token);

        SafeERC20.safeTransfer(token, _receiver, _amount);
    }

}
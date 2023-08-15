// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

// synthetix v3
import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";
import {ISpotMarketProxy} from "src/interfaces/synthetix/ISpotMarketProxy.sol";

// tokens
import {IERC20} from "src/interfaces/tokens/IERC20.sol";

// utils
import {Multicallable} from "src/utils/Multicallable.sol";

// libraries
import {Int128Lib} from "src/libraries/Int128Lib.sol";
import {Int256Lib} from "src/libraries/Int256Lib.sol";

contract Engine is Multicallable {
    using Int128Lib for int128;
    using Int256Lib for int256;

    bytes32 internal constant ADMIN_PERMISSION = "ADMIN";
    bytes32 internal constant TRACKING_CODE = "KWENTA";
    address internal constant REFERRER = address(0);

    IPerpsMarketProxy public immutable PERPS_MARKET_PROXY;
    ISpotMarketProxy public immutable SPOT_MARKET_PROXY;
    IERC20 public immutable SUSD;

    error Unauthorized();

    constructor(
        address _perpsMarketProxy,
        address _spotMarketProxy,
        address _sUSDProxy
    ) {
        PERPS_MARKET_PROXY = IPerpsMarketProxy(_perpsMarketProxy);
        SPOT_MARKET_PROXY = ISpotMarketProxy(_spotMarketProxy);
        SUSD = IERC20(_sUSDProxy);
    }

    function modifyCollateral(
        uint128 _accountId,
        uint128 _synthMarketId,
        int256 _amount
    ) external {
        IERC20 synth = IERC20(_getSynthAddress(_synthMarketId));

        if (_amount > 0) {
            // @dev given the amount is positive, simply casting (int -> uint) is safe
            synth.transferFrom(msg.sender, address(this), uint256(_amount));

            synth.approve(address(PERPS_MARKET_PROXY), uint256(_amount));

            PERPS_MARKET_PROXY.modifyCollateral(
                _accountId, _synthMarketId, _amount
            );
        } else {
            /// @dev only the account owner can withdraw collateral
            if (PERPS_MARKET_PROXY.getAccountOwner(_accountId) != msg.sender) {
                revert Unauthorized();
            }

            /// @dev given the amount is negative, simply casting (int -> uint) is unsafe, thus we use .abs()
            PERPS_MARKET_PROXY.modifyCollateral(
                _accountId, _synthMarketId, _amount
            );

            synth.transfer(msg.sender, _amount.abs());
        }
    }

    function _getSynthAddress(uint128 _synthMarketId)
        internal
        view
        returns (address synthAddress)
    {
        /// @dev "0" synthMarketId represents sUSD in Synthetix v3
        synthAddress = _synthMarketId == 0
            ? address(SUSD)
            : SPOT_MARKET_PROXY.getSynth(_synthMarketId);
    }

    function commitOrder(
        uint128 _perpsMarketId,
        uint128 _accountId,
        int128 _sizeDelta,
        uint128 _settlementStrategyId,
        uint256 _acceptablePrice
    ) external {
        /// @dev only the account owner can withdraw collateral
        if (
            PERPS_MARKET_PROXY.getAccountOwner(_accountId) == msg.sender
                || PERPS_MARKET_PROXY.hasPermission(
                    _accountId, ADMIN_PERMISSION, msg.sender
                )
        ) {
            (, uint256 fees) = PERPS_MARKET_PROXY.commitOrder(
                IPerpsMarketProxy.OrderCommitmentRequest({
                    marketId: _perpsMarketId,
                    accountId: _accountId,
                    sizeDelta: _sizeDelta,
                    settlementStrategyId: _settlementStrategyId,
                    acceptablePrice: _acceptablePrice,
                    trackingCode: TRACKING_CODE,
                    referrer: REFERRER
                })
            );
        } else {
            revert Unauthorized();
        }
    }
}

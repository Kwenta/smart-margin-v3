// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Auth, IPerpsMarketProxy} from "src/modules/Auth.sol";
import {IEngine} from "src/interfaces/IEngine.sol";
import {ISpotMarketProxy} from "src/interfaces/synthetix/ISpotMarketProxy.sol";
import {IERC20} from "src/interfaces/tokens/IERC20.sol";
import {Stats} from "src/modules/Stats.sol";
import {Multicallable} from "src/utils/Multicallable.sol";
import {Int128Lib} from "src/libraries/Int128Lib.sol";
import {Int256Lib} from "src/libraries/Int256Lib.sol";

/// @title Kwenta Smart Margin v3: Engine contract
/// @notice Responsible for interacting with Synthetix v3 perps markets
/// @author JaredBorders (jaredborders@pm.me)
contract Engine is IEngine, Stats, Auth, Multicallable {
    using Int128Lib for int128;
    using Int256Lib for int256;

    /// @notice tracking code submitted with trades to identify the source of the trade
    bytes32 internal constant TRACKING_CODE = "KWENTA";

    /// @notice the address of the kwenta treasury multisig; used for source of collecting fees
    address internal constant REFERRER =
        0xF510a2Ff7e9DD7e18629137adA4eb56B9c13E885;

    /// @notice Synthetix v3 spot market proxy contract
    ISpotMarketProxy internal immutable SPOT_MARKET_PROXY;

    /// @notice Synthetix v3 sUSD contract
    IERC20 internal immutable SUSD;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Constructs the Engine contract
    /// @param _perpsMarketProxy Synthetix v3 perps market proxy contract
    /// @param _spotMarketProxy Synthetix v3 spot market proxy contract
    /// @param _sUSDProxy Synthetix v3 sUSD contract
    constructor(
        address _perpsMarketProxy,
        address _spotMarketProxy,
        address _sUSDProxy
    ) Auth(_perpsMarketProxy) {
        SPOT_MARKET_PROXY = ISpotMarketProxy(_spotMarketProxy);
        SUSD = IERC20(_sUSDProxy);
    }

    /*//////////////////////////////////////////////////////////////
                         COLLATERAL MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEngine
    function modifyCollateral(
        uint128 _accountId,
        uint128 _synthMarketId,
        int256 _amount
    ) external override {
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
            if (!isAccountOwner(_accountId)) revert Unauthorized();

            /// @dev given the amount is negative, simply casting (int -> uint) is unsafe, thus we use .abs()
            PERPS_MARKET_PROXY.modifyCollateral(
                _accountId, _synthMarketId, _amount
            );

            synth.transfer(msg.sender, _amount.abs());
        }
    }

    /// @notice query and return the address of the synth contract
    /// @param _synthMarketId the id of the synth market
    /// @return  synthAddress address of the synth based on the synth market id
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

    /*//////////////////////////////////////////////////////////////
                         ASYNC ORDER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEngine
    function commitOrder(
        uint128 _perpsMarketId,
        uint128 _accountId,
        int128 _sizeDelta,
        uint128 _settlementStrategyId,
        uint256 _acceptablePrice
    ) external override {
        /// @dev only the account owner can withdraw collateral
        if (isAccountOwner(_accountId) || isAccountDelegate(_accountId)) {
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

            _updateAccountStats(_accountId, fees, _sizeDelta.abs());
        } else {
            revert Unauthorized();
        }
    }
}

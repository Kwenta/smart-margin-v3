// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Auth, ERC721Receiver} from "src/modules/Auth.sol";
import {IERC20} from "src/interfaces/tokens/IERC20.sol";
import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";
import {Int256Lib} from "src/libraries/Int256Lib.sol";
import {Int128Lib} from "src/libraries/Int128Lib.sol";
import {ISpotMarketProxy} from "src/interfaces/synthetix/ISpotMarketProxy.sol";
import {Multicallable} from "src/utils/Multicallable.sol";
import {Stats} from "src/modules/Stats.sol";

/// @custom:todo add docs
/// @custom:todo create interface once well tested and stable

/// @title Kwenta Smart Margin v3: Margin Engine
/// @notice Responsible for interacting with Synthetix v3 Perps Market
/// @author JaredBorders (jaredborders@pm.me)
contract MarginEngine is Multicallable, ERC721Receiver {
    using Int128Lib for int128;
    using Int256Lib for int256;

    bytes32 internal constant TRACKING_CODE = "KWENTA";

    Auth public immutable AUTH;
    IPerpsMarketProxy public immutable PERPS_MARKET_PROXY;
    ISpotMarketProxy public immutable SPOT_MARKET_PROXY;
    Stats public immutable STATS;
    IERC20 public immutable SUSD;

    constructor(
        address _auth,
        address _stats,
        address _perpsMarketProxy,
        address _spotMarketProxy,
        address _sUSDProxy
    ) {
        AUTH = Auth(_auth);
        PERPS_MARKET_PROXY = IPerpsMarketProxy(_perpsMarketProxy);
        SPOT_MARKET_PROXY = ISpotMarketProxy(_spotMarketProxy);
        STATS = Stats(_stats);
        SUSD = IERC20(_sUSDProxy);
    }

    /*//////////////////////////////////////////////////////////////
                         COLLATERAL MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function depositCollateral(
        uint128 _accountId,
        uint128 _synthMarketId,
        int256 _amount
    ) external {
        assert(AUTH.isCallerAccountActor(msg.sender, _accountId));

        /// @dev given the amount is positive, simply casting (int -> uint) is safe
        assert(_amount > 0);

        address synthAddress = _getSynthAddress(_synthMarketId);

        IERC20(synthAddress).transferFrom(
            msg.sender, address(this), uint256(_amount)
        );

        IERC20(synthAddress).approve(
            address(PERPS_MARKET_PROXY), uint256(_amount)
        );

        PERPS_MARKET_PROXY.modifyCollateral(_accountId, _synthMarketId, _amount);
    }

    function withdrawCollateral(
        uint128 _accountId,
        uint128 _synthMarketId,
        int256 _amount
    ) external {
        assert(AUTH.isCallerAccountActor(msg.sender, _accountId));

        /// @dev given the amount is negative, simply casting (int -> uint) is unsafe, thus we use .abs()
        assert(_amount < 0);

        PERPS_MARKET_PROXY.modifyCollateral(_accountId, _synthMarketId, _amount);

        address synthAddress = _getSynthAddress(_synthMarketId);

        IERC20(synthAddress).transfer(msg.sender, _amount.abs());
    }

    function _getSynthAddress(uint128 _synthMarketId)
        internal
        view
        returns (address synthAddress)
    {
        /// @dev synthMarketId of 0 internally represents sUSD in SNXv3 system (see SNXv3 PerpsAccountModule)
        /// but getSynth(0) will not return sUSD address so it must be handled separately 🙃
        synthAddress = _synthMarketId == 0
            ? address(SUSD)
            : SPOT_MARKET_PROXY.getSynth(_synthMarketId);
        assert(synthAddress != address(0));
    }

    /*//////////////////////////////////////////////////////////////
                         ASYNC ORDER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function commitOrder(
        uint128 _perpsMarketId,
        uint128 _accountId,
        int128 _sizeDelta,
        uint128 _settlementStrategyId,
        uint256 _acceptablePrice,
        address _referrer
    ) external {
        assert(
            AUTH.isCallerAccountDelegate(msg.sender, _accountId)
                || AUTH.isCallerAccountActor(msg.sender, _accountId)
        );

        (, uint256 fees) = PERPS_MARKET_PROXY.commitOrder(
            IPerpsMarketProxy.OrderCommitmentRequest({
                marketId: _perpsMarketId,
                accountId: _accountId,
                sizeDelta: _sizeDelta,
                settlementStrategyId: _settlementStrategyId,
                acceptablePrice: _acceptablePrice,
                trackingCode: TRACKING_CODE,
                referrer: _referrer
            })
        );
        /// @custom:todo who should receive the referrer fees?

        STATS.updateAccountStats({
            _accountId: _accountId,
            _fees: fees,
            _volume: _sizeDelta.abs()
        });
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Auth, ERC721Receiver} from "src/modules/Auth.sol";
import {IERC20} from "src/interfaces/tokens/IERC20.sol";
import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";
import {Int256Lib} from "src/libraries/INT256Lib.sol";
import {Int128Lib} from "src/libraries/INT128Lib.sol";
import {ISpotMarketProxy} from "src/interfaces/synthetix/ISpotMarketProxy.sol";
import {Multicallable} from "src/utils/Multicallable.sol";

contract MarginEngine is Multicallable, ERC721Receiver {
    using Int128Lib for int128;
    using Int256Lib for int256;

    bytes32 internal constant TRACKING_CODE = "KWENTA";

    Auth public immutable AUTH;
    IPerpsMarketProxy public immutable PERPS_MARKET_PROXY;
    ISpotMarketProxy public immutable SPOT_MARKET_PROXY;
    IERC20 public immutable SUSD;

    struct AccountStats {
        uint256 totalFees;
        uint128 totalVolume;
        uint128 totalTrades;
    }

    mapping(uint128 accountId => AccountStats) public accountStats;

    constructor(
        address _auth,
        address _perpsMarketProxy,
        address _spotMarketProxy,
        address _sUSDProxy
    ) {
        AUTH = Auth(_auth);
        PERPS_MARKET_PROXY = IPerpsMarketProxy(_perpsMarketProxy);
        SPOT_MARKET_PROXY = ISpotMarketProxy(_spotMarketProxy);
        SUSD = IERC20(_sUSDProxy);
    }

    /*//////////////////////////////////////////////////////////////
                           ACCOUNT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function createAccount() external returns (uint128 accountId) {
        accountId = AUTH.createAccount({_actor: msg.sender});
    }

    /*//////////////////////////////////////////////////////////////
                         COLLATERAL MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function depositCollateral(
        uint128 _accountId,
        uint128 _synthMarketId,
        int256 _amount
    ) external {
        assert(AUTH.isActorAccountOwner(msg.sender, _accountId));
        assert(_amount > 0);

        address synthAddress = _getSynthAddress(_synthMarketId);

        IERC20(synthAddress).transferFrom(
            msg.sender, address(this), _amount.abs()
        );

        IERC20(synthAddress).approve(address(PERPS_MARKET_PROXY), _amount.abs());

        PERPS_MARKET_PROXY.modifyCollateral(_accountId, _synthMarketId, _amount);
    }

    function withdrawCollateral(
        uint128 _accountId,
        uint128 _synthMarketId,
        int256 _amount
    ) external {
        assert(AUTH.isActorAccountOwner(msg.sender, _accountId));
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
        uint128 _marketId,
        uint128 _accountId,
        int128 _sizeDelta,
        uint128 _settlementStrategyId,
        uint256 _acceptablePrice,
        address _referrer
    ) external {
        assert(
            AUTH.isActorDelegate(msg.sender, _accountId)
                || AUTH.isActorAccountOwner(msg.sender, _accountId)
        );

        (, uint256 fees) = PERPS_MARKET_PROXY.commitOrder(
            IPerpsMarketProxy.OrderCommitmentRequest({
                marketId: _marketId,
                accountId: _accountId,
                sizeDelta: _sizeDelta,
                settlementStrategyId: _settlementStrategyId,
                acceptablePrice: _acceptablePrice,
                trackingCode: TRACKING_CODE,
                referrer: _referrer
            })
        );
        /// @custom:todo who should receive the referrer fees?

        /// @dev track account stats
        accountStats[_accountId].totalFees += fees;
        accountStats[_accountId].totalVolume += _sizeDelta.abs();
        accountStats[_accountId].totalTrades++;
    }
}

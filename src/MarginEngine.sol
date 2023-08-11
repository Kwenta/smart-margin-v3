// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Auth, ERC721Receiver} from "src/modules/Auth.sol";
import {IERC20} from "src/interfaces/tokens/IERC20.sol";
import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";
import {Int256Lib} from "src/libraries/INT256Lib.sol";
import {ISpotMarketProxy} from "src/interfaces/synthetix/ISpotMarketProxy.sol";
import {Multicallable} from "src/utils/Multicallable.sol";

contract MarginEngine is Multicallable, ERC721Receiver {
    using Int256Lib for int256;

    Auth public immutable AUTH;
    IPerpsMarketProxy public immutable PERPS_MARKET_PROXY;
    ISpotMarketProxy public immutable SPOT_MARKET_PROXY;
    IERC20 public immutable SUSD;

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

    function createAccount() external returns (uint128 accountId) {
        accountId = AUTH.createAccount({_actor: msg.sender});
    }

    function depositCollateral(
        uint128 _accountId,
        uint128 _synthMarketId,
        int256 _amount
    ) external {
        assert(AUTH.isActorAccountOwner(msg.sender, _accountId));
        assert(_amount > 0);

        /// @dev synthMarketId of 0 internally represents sUSD in SNXv3 system (see SNXv3 PerpsAccountModule)
        /// but getSynth(0) will not return sUSD address so it must be handled separately 🙃
        address synthAddress = _synthMarketId == 0
            ? address(SUSD)
            : SPOT_MARKET_PROXY.getSynth(_synthMarketId);
        assert(synthAddress != address(0));

        IERC20(synthAddress).transferFrom(
            msg.sender, address(this), _amount.abs()
        );

        IERC20(synthAddress).approve(address(PERPS_MARKET_PROXY), _amount.abs());

        PERPS_MARKET_PROXY.modifyCollateral(_accountId, _synthMarketId, _amount);
    }
}

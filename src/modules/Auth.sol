// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IAuth} from "src/interfaces/modules/IAuth.sol";
import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";

/// @title Kwenta Smart Margin v3: Engine contract
/// @notice Responsible for interacting with Synthetix v3 perps markets
/// @author JaredBorders (jaredborders@pm.me)
contract Auth is IAuth {
    /// @notice admins have permission to do everything that the account owner can
    /// (including granting and revoking permissions for other addresses) except
    /// for transferring account ownership
    bytes32 internal constant ADMIN_PERMISSION = "ADMIN";

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Synthetix v3 perps market proxy contract
    IPerpsMarketProxy internal immutable PERPS_MARKET_PROXY;

    /// @notice Constructs the Auth contract
    /// @param _perpsMarketProxy Synthetix v3 perps market proxy contractt
    constructor(address _perpsMarketProxy) {
        PERPS_MARKET_PROXY = IPerpsMarketProxy(_perpsMarketProxy);
    }

    /*//////////////////////////////////////////////////////////////
                             AUTHENTICATION
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IAuth
    function isAccountOwner(uint128 _accountId)
        public
        view
        override
        returns (bool)
    {
        return PERPS_MARKET_PROXY.getAccountOwner(_accountId) == msg.sender;
    }

    /// @inheritdoc IAuth
    function isAccountDelegate(uint128 _accountId)
        public
        view
        override
        returns (bool)
    {
        return PERPS_MARKET_PROXY.hasPermission(
            _accountId, ADMIN_PERMISSION, msg.sender
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @title Consolidated Spot Market Proxy Interface
/// @notice Responsible for interacting with Synthetix v3 spot markets
/// @author Synthetix
interface ISpotMarketProxy {
    /*//////////////////////////////////////////////////////////////
                       SPOT MARKET FACTORY MODULE
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the proxy address of the synth for the provided marketId
    /// @dev Uses associated systems module to retrieve the token address.
    /// @param marketId id of the market
    /// @return synthAddress address of the proxy for the synth
    function getSynth(uint128 marketId)
        external
        view
        returns (address synthAddress);
}

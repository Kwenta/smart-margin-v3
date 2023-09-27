// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IERC7412} from "src/interfaces/synthetix/IERC7412.sol";

/// @title Kwenta Smart Margin v3: EIP-7412 Utility Contract
/// @notice Responsible for fulfilling EIP-7412 oracle queries
/// @author JaredBorders (jaredborders@pm.me)
contract EIP7412 {
    /// @notice Fulfill an EIP-7412 oracle query
    /// @param EIP7412Implementer The address of the EIP-7412 implementer
    /// @param signedOffchainData The data that was returned
    /// from the off-chain interface, signed by the oracle
    function fulfillOracleQuery(
        address EIP7412Implementer,
        bytes calldata signedOffchainData
    ) external payable {
        IERC7412(EIP7412Implementer).fulfillOracleQuery(signedOffchainData);
    }
}

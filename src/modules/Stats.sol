// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

// utils
import {Ownable} from "src/utils/Ownable.sol";

/// @custom:todo add more stats? (e.g. conditional orders placed, etc)

/// @title Kwenta Smart Margin v3: Stats Module
/// @notice Responsible for recording stats for accounts trading on verified margin engines
/// @dev Given the purpose of this contract, events are never emitted when updating stats
/// @author JaredBorders (jaredborders@pm.me)
contract Stats is Ownable {
    /// @notice stats for an account
    /// @custom:property totalFees the total fees paid by the account
    /// @custom:property totalVolume the total volume traded by the account
    /// @custom:property totalTrades the total number of trades made by the account
    struct AccountStats {
        uint256 totalFees;
        uint128 totalVolume;
        uint128 totalTrades;
    }

    /// @notice mapping that stores stats for an account
    mapping(uint128 accountId => AccountStats) internal accountStats;

    /// @notice mapping that stores margin engine registration status
    mapping(address marginEngine => bool status) public registeredMarginEngines;

    /// @notice thrown when a the caller is not a validated margin engine
    error InvalidMarginEngine(address marginEngine);

    /// @notice initialize the owner
    /// @param _owner the owner of the contract
    /// @dev _owner will be Kwenta pDAO multisig
    constructor(address _owner) {
        _initializeOwner(_owner);
    }

    /// @notice get the stats for an account
    /// @param _accountId the account to get stats for
    function getAccountStats(uint128 _accountId)
        external
        view
        returns (AccountStats memory)
    {
        return accountStats[_accountId];
    }

    /// @notice register a margin engine
    /// @param _marginEngine the margin engine to register
    /// @dev only callable by the owner
    /// @dev no checks are made on the _marginEngine address (could be a contract, an EOA, zero address, etc)
    function registerMarginEngine(address _marginEngine) external onlyOwner {
        registeredMarginEngines[_marginEngine] = true;
    }

    /// @notice update the stats of an account
    /// @param _accountId the account to update
    /// @param _fees the fees to add to the account
    /// @param _volume the volume to add to the account
    /// @dev only callable by a validated margin engine
    function updateAccountStats(
        uint128 _accountId,
        uint256 _fees,
        uint128 _volume
    ) external {
        if (!registeredMarginEngines[msg.sender]) {
            revert InvalidMarginEngine(msg.sender);
        }

        AccountStats storage stats = accountStats[_accountId];

        stats.totalFees += _fees;
        stats.totalVolume += _volume;
        stats.totalTrades++;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @title Kwenta Smart Margin v3: Authentication Module Events
/// @notice Defines all events emitted by the Authentication Module
/// @author JaredBorders (jaredborders@pm.me)
contract AuthEvents {
    /// @notice emitted when an account is created
    /// @param accountId the id of the created account
    /// @param actor the actor for the account
    event AccountCreated(uint128 indexed accountId, address indexed actor);

    /// @notice emitted when an account actor is changed
    /// @param accountId the account that had its actor changed
    /// @param oldActor the old actor for the account
    /// @param newActor the new actor for the account
    event AccountActorChanged(
        uint128 indexed accountId,
        address indexed oldActor,
        address indexed newActor
    );

    /// @notice emitted when a delegate is added to an account
    /// @param accountId the account the delegate was added to
    /// @param delegate the delegate that was added
    event AccountDelegateAdded(
        uint128 indexed accountId, address indexed delegate
    );

    /// @notice emitted when a delegate is removed from an account
    /// @param accountId the account the delegate was removed from
    /// @param delegate the delegate that was removed
    event AccountDelegateRemoved(
        uint128 indexed accountId, address indexed delegate
    );

    /// @notice emitted when a margin engine is registered with an account
    /// @param accountId the account the margin engine was registered to
    /// @param marginEngine the margin engine that was registered
    event MarginEngineRegistered(
        uint128 indexed accountId, address indexed marginEngine
    );

    /// @notice emitted when a margin engine is unregistered from an account
    /// @param accountId the account the margin engine was unregistered from
    /// @param marginEngine the margin engine that was unregistered
    event MarginEngineUnregistered(
        uint128 indexed accountId, address indexed marginEngine
    );
}

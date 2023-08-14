// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @title Kwenta Smart Margin v3: Authentication Module Interface
/// @author JaredBorders (jaredborders@pm.me)
interface IAuth {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice thrown when the caller is not the permissioned account actor
    /// @param accountId the account to check the actor for
    /// @param accountActor the actor for the account
    /// @param caller the caller of the function
    /// @notice this error is thrown when caller != accountActor
    error OnlyAccountActor(
        uint128 accountId, address accountActor, address caller
    );

    /// @notice thrown when the margin engine is not registered with the account
    /// and the account actor attempts to unregister it
    /// @param accountId the account to unregister the margin engine from
    /// @param marginEngine the margin engine to unregister
    error MarginEngineNotRegistered(uint128 accountId, address marginEngine);

    /// @notice thrown when provided address is inappropriate zero address
    error ZeroAddress();

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice checks if "_caller" is the account actor for the account with "_accountId"
    /// @dev msg.sender is not necessarily the caller (and likely isn't)
    /// @param _caller the address to check
    /// @param _accountId the account to check the actor for
    /// @return isActor true if the "_caller" is the account actor
    function isCallerAccountActor(address _caller, uint128 _accountId)
        external
        view
        returns (bool);

    /// @notice get the actor for an account with "_accountId"
    /// @param _accountId the account to get the actor for
    /// @return the actor for the account
    function getActorByAccountId(uint128 _accountId)
        external
        view
        returns (address);

    /// @notice get the account ids for the given actor
    /// @param _accountActor the actor to get the account ids for
    /// @return the account ids associated with the actor
    function getAccountIdsByActor(address _accountActor)
        external
        view
        returns (uint128[] memory);

    /// @notice checks if "_caller" is a delegate for the account with "_accountId"
    /// @dev msg.sender is not necessarily the caller (and likely isn't)
    /// @param _caller the address to check
    /// @param _accountId the account to check the delegate for
    /// @return isDelegate true if the "_caller" is a delegate for the account
    function isCallerAccountDelegate(address _caller, uint128 _accountId)
        external
        view
        returns (bool);

    /// @notice get the delegates for an account with "_accountId"
    /// @param _accountId the account to get the delegates for
    /// @return the delegates for the account
    function getDelegatesByAccountId(uint128 _accountId)
        external
        view
        returns (address[] memory);

    /// @notice get the account ids for the given delegate
    /// @param _delegate the delegate to get the account ids for
    /// @return the account ids associated with the delegate
    function getAccountIdsByDelegate(address _delegate)
        external
        view
        returns (uint128[] memory);

    /// @notice checks if "_marginEngine" is registered with the account with "_accountId"
    /// @param _accountId the account to check the margin engine for
    /// @param _marginEngine the margin engine to check
    /// @return whether the "_marginEngine" is registered with the account
    function hasAccountRegisteredMarginEngine(
        uint128 _accountId,
        address _marginEngine
    ) external view returns (bool);

    /// @notice create a Synthetix v3 perps market account
    /// @return accountId the id of the created account
    function createAccount() external returns (uint128 accountId);

    /// @notice create a Synthetix v3 perps market account
    /// and register a margin engine with the account
    /// @param _marginEngine the margin engine to register
    /// @return accountId the id of the created account
    function createAccount(address _marginEngine)
        external
        returns (uint128 accountId);

    /// @notice change the actor for an account
    /// @notice the caller must be the current actor for the account
    /// @param _accountId the account to change the actor for
    function changeAccountActor(uint128 _accountId, address _newActor)
        external;

    /// @notice add a delegate to an account
    /// @notice the caller must be the account actor
    /// @param _accountId the account to add the delegate to
    /// @param _delegate the delegate to add
    function addDelegate(uint128 _accountId, address _delegate) external;

    /// @notice remove a delegate from an account
    /// @notice the caller must be the account actor
    /// @param _accountId the account to remove the delegate from
    /// @param _delegate the delegate to remove
    function removeDelegate(uint128 _accountId, address _delegate) external;

    /// @notice register a margin engine with an account
    /// @dev registering allows an actor or delegate associated
    /// with an account to trade via the margin engine
    /// @param _accountId the account to register the margin engine to
    /// @param _marginEngine the margin engine to register
    function registerMarginEngine(uint128 _accountId, address _marginEngine)
        external;

    /// @notice unregister a margin engine from an account
    /// @dev unregistering prevents an actor or delegate associated
    /// with an account from trading via the margin engine
    /// @param _accountId the account to unregister the margin engine from
    /// @param _marginEngine the margin engine to unregister
    function unregisterMarginEngine(uint128 _accountId, address _marginEngine)
        external;
}

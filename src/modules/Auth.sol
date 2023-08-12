// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {ERC721Receiver} from "src/tokens/ERC721Receiver.sol";
import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";

/// @custom:todo create interface once well tested and stable
/// @custom:todo add events
/// @custom:todo unit test events
/// @custom:todo further unit test all functions (fuzz, etc.)
/// @custom:todo review all for-loops and optimize where possible

/// @title Kwenta Smart Margin v3: Authentication Module
/// @notice Responsible for managing accounts and permissions
/// @author JaredBorders (jaredborders@pm.me)
contract Auth is ERC721Receiver {
    /*//////////////////////////////////////////////////////////////
                          CONSTANTS/IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice ADMIN's have permission to do everything except for transferring account ownership
    bytes32 internal constant _ADMIN_PERMISSION = "ADMIN";

    /// @notice Synthetix v3 perps market proxy
    IPerpsMarketProxy internal immutable PERPS_MARKET_PROXY;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice mapping stores the actor for a given account
    mapping(uint128 accountId => address accountActor) internal actorByAccountId;

    /// @notice mapping stores the accounts for a given actor
    mapping(address accountActor => uint128[] accountIds) internal
        accountIdsByActor;

    /// @notice mapping stores whether or not the given delegate
    /// is a delegate for the given account
    mapping(uint128 accountId => mapping(address delegate => bool isDelegate))
        internal isDelegateByAccountId;

    /// @notice mapping stores the delegates for a given account
    mapping(uint128 accountId => address[] delegates) internal
        delegatesByAccountId;

    /// @notice mapping stores the accounts a given delegate is a delegate for
    mapping(address delegate => uint128[] accountIds) internal
        accountIdsByDelegate;

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
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice only the account actor can call a function with this modifier
    /// @param _accountId the account to check the actor for
    modifier onlyAccountActor(uint128 _accountId) {
        _onlyAccountActor(_accountId);

        _;
    }

    function _onlyAccountActor(uint128 _accountId) internal view {
        /// @dev if actorByAccountId[_accountId] == address(0),
        /// then the account does not exist and the caller is not the actor
        if (actorByAccountId[_accountId] != msg.sender) {
            revert OnlyAccountActor({
                accountId: _accountId,
                accountActor: actorByAccountId[_accountId],
                caller: msg.sender
            });
        }
    }

    /// @notice checks provided address is not the inappropriate zero address
    /// @param _address the address to check
    modifier notZeroAddress(address _address) {
        _notZeroAddress(_address);

        _;
    }

    function _notZeroAddress(address _address) internal pure {
        if (_address == address(0)) revert ZeroAddress();
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice initialize the Synthetix v3 perps market proxy
    /// @param _perpsMarketProxy the Synthetix v3 perps market proxy
    constructor(address _perpsMarketProxy) {
        PERPS_MARKET_PROXY = IPerpsMarketProxy(_perpsMarketProxy);
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    function isCallerAccountActor(address _caller, uint128 _accountId)
        public
        view
        returns (bool)
    {
        return actorByAccountId[_accountId] == _caller;
    }

    function getActorByAccountId(uint128 _accountId)
        external
        view
        returns (address)
    {
        return actorByAccountId[_accountId];
    }

    function getAccountIdsByActor(address _accountActor)
        external
        view
        returns (uint128[] memory)
    {
        return accountIdsByActor[_accountActor];
    }

    function isCallerAccountDelegate(address _caller, uint128 _accountId)
        public
        view
        returns (bool)
    {
        return isDelegateByAccountId[_accountId][_caller];
    }

    function getDelegatesByAccountId(uint128 _accountId)
        external
        view
        returns (address[] memory)
    {
        return delegatesByAccountId[_accountId];
    }

    function getAccountIdsByDelegate(address _delegate)
        external
        view
        returns (uint128[] memory)
    {
        return accountIdsByDelegate[_delegate];
    }

    function hasAccountRegisteredMarginEngine(
        uint128 _accountId,
        address _marginEngine
    ) public view returns (bool) {
        return PERPS_MARKET_PROXY.hasPermission({
            accountId: _accountId,
            permission: _ADMIN_PERMISSION,
            user: _marginEngine
        });
    }

    /*//////////////////////////////////////////////////////////////
                           ACCOUNT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice create a Synthetix v3 perps market account
    /// @return accountId the id of the created account
    function createAccount() external returns (uint128 accountId) {
        /// @dev this auth contract will ALWAYS be the actual owner of the account
        accountId = PERPS_MARKET_PROXY.createAccount();

        /// @dev caller will be the account actor
        actorByAccountId[accountId] = msg.sender;
        accountIdsByActor[msg.sender].push(accountId);
    }

    /// @notice create a Synthetix v3 perps market account
    /// and register a margin engine with the account
    /// @param _marginEngine the margin engine to register
    /// @return accountId the id of the created account
    function createAccount(address _marginEngine)
        external
        notZeroAddress(_marginEngine)
        returns (uint128 accountId)
    {
        /// @dev this auth contract will ALWAYS be the actual owner of the account
        accountId = PERPS_MARKET_PROXY.createAccount();

        PERPS_MARKET_PROXY.grantPermission({
            accountId: accountId,
            permission: _ADMIN_PERMISSION,
            user: _marginEngine
        });

        /// @dev caller will be the account actor
        actorByAccountId[accountId] = msg.sender;
        accountIdsByActor[msg.sender].push(accountId);
    }

    /*//////////////////////////////////////////////////////////////
                            ACTOR MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice change the actor for an account
    /// @notice the caller must be the current actor for the account
    /// @param _accountId the account to change the actor for
    function changeAccountActor(uint128 _accountId, address _newActor)
        external
        onlyAccountActor(_accountId)
        notZeroAddress(_newActor)
    {
        // remove old actor
        _removeAccountIdFromAccountIdsByActor(_accountId);

        // add new actor
        actorByAccountId[_accountId] = _newActor;
        accountIdsByActor[_newActor].push(_accountId);
    }

    /// @notice remove account from accountIdsByActor mapping
    /// @param _accountId the account to remove
    function _removeAccountIdFromAccountIdsByActor(uint128 _accountId)
        internal
    {
        uint128[] memory accountIds = accountIdsByActor[msg.sender];

        uint256 accountIdsLength = accountIds.length;

        for (uint256 i = 0; i < accountIdsLength;) {
            if (accountIds[i] == _accountId) {
                accountIds[i] = accountIds[accountIdsLength - 1];
                accountIdsByActor[msg.sender] = accountIds;
                accountIdsByActor[msg.sender].pop();
                return;
            }

            unchecked {
                ++i;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                          DELEGATE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice add a delegate to an account
    /// @notice the caller must be the account actor
    /// @param _accountId the account to add the delegate to
    /// @param _delegate the delegate to add
    function addDelegate(uint128 _accountId, address _delegate)
        external
        onlyAccountActor(_accountId)
        notZeroAddress(_delegate)
    {
        isDelegateByAccountId[_accountId][_delegate] = true;

        delegatesByAccountId[_accountId].push(_delegate);
        accountIdsByDelegate[_delegate].push(_accountId);
    }

    /// @notice remove a delegate from an account
    /// @notice the caller must be the account actor
    /// @param _accountId the account to remove the delegate from
    /// @param _delegate the delegate to remove
    function removeDelegate(uint128 _accountId, address _delegate)
        external
        onlyAccountActor(_accountId)
    {
        isDelegateByAccountId[_accountId][_delegate] = false;

        _removeDelegateFromDelegatesByAccountId(_accountId, _delegate);
        _removeDelegateFromAccountIdsByDelegate(_accountId, _delegate);
    }

    /// @notice remove a delegate from delegatesByAccountId mapping
    /// @param _accountId the account to remove the delegate from
    /// @param _delegate the delegate to remove
    function _removeDelegateFromDelegatesByAccountId(
        uint128 _accountId,
        address _delegate
    ) internal {
        address[] memory delegates = delegatesByAccountId[_accountId];

        uint256 delegatesLength = delegates.length;

        for (uint256 i = 0; i < delegatesLength;) {
            if (delegates[i] == _delegate) {
                delegates[i] = delegates[delegatesLength - 1];
                delegatesByAccountId[_accountId] = delegates;
                delegatesByAccountId[_accountId].pop();
                return;
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice remove a delegate from accountIdsByDelegate mapping
    /// @param _accountId the account to remove the delegate from
    /// @param _delegate the delegate to remove
    function _removeDelegateFromAccountIdsByDelegate(
        uint128 _accountId,
        address _delegate
    ) internal {
        uint128[] memory accountIds = accountIdsByDelegate[_delegate];

        uint256 accountIdsLength = accountIds.length;

        for (uint256 i = 0; i < accountIdsLength;) {
            if (accountIds[i] == _accountId) {
                accountIds[i] = accountIds[accountIdsLength - 1];
                accountIdsByDelegate[_delegate] = accountIds;
                accountIdsByDelegate[_delegate].pop();
                return;
            }

            unchecked {
                ++i;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        MARGIN ENGINE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice register a margin engine with an account
    /// @dev registering allows an actor or delegate associated
    /// with an account to trade via the margin engine
    /// @param _accountId the account to register the margin engine to
    /// @param _marginEngine the margin engine to register
    function registerMarginEngine(uint128 _accountId, address _marginEngine)
        external
        onlyAccountActor(_accountId)
        notZeroAddress(_marginEngine)
    {
        PERPS_MARKET_PROXY.grantPermission({
            accountId: _accountId,
            permission: _ADMIN_PERMISSION,
            user: _marginEngine
        });
    }

    /// @notice unregister a margin engine from an account
    /// @dev unregistering prevents an actor or delegate associated
    /// with an account from trading via the margin engine
    /// @param _accountId the account to unregister the margin engine from
    /// @param _marginEngine the margin engine to unregister
    function unregisterMarginEngine(uint128 _accountId, address _marginEngine)
        external
        onlyAccountActor(_accountId)
    {
        if (hasAccountRegisteredMarginEngine(_accountId, _marginEngine)) {
            PERPS_MARKET_PROXY.revokePermission({
                accountId: _accountId,
                permission: _ADMIN_PERMISSION,
                user: _marginEngine
            });
        } else {
            revert MarginEngineNotRegistered({
                accountId: _accountId,
                marginEngine: _marginEngine
            });
        }
    }
}

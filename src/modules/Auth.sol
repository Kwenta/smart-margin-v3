// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

// auth
import {IAuth} from "src/interfaces/modules/IAuth.sol";
import {AuthEvents} from "src/events/modules/AuthEvents.sol";

// synthetix v3
import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";

// tokens
import {ERC721Receiver} from "src/tokens/ERC721Receiver.sol";

/// @title Kwenta Smart Margin v3: Authentication Module
/// @notice Responsible for managing accounts and permissions
/// @author JaredBorders (jaredborders@pm.me)
contract Auth is IAuth, AuthEvents, ERC721Receiver {
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

    /// @inheritdoc IAuth
    function isCallerAccountActor(address _caller, uint128 _accountId)
        public
        view
        returns (bool)
    {
        return actorByAccountId[_accountId] == _caller;
    }

    /// @inheritdoc IAuth
    function getActorByAccountId(uint128 _accountId)
        external
        view
        returns (address)
    {
        return actorByAccountId[_accountId];
    }

    /// @inheritdoc IAuth
    function getAccountIdsByActor(address _accountActor)
        external
        view
        returns (uint128[] memory)
    {
        return accountIdsByActor[_accountActor];
    }

    /// @inheritdoc IAuth
    function isCallerAccountDelegate(address _caller, uint128 _accountId)
        public
        view
        returns (bool)
    {
        return isDelegateByAccountId[_accountId][_caller];
    }

    /// @inheritdoc IAuth
    function getDelegatesByAccountId(uint128 _accountId)
        external
        view
        returns (address[] memory)
    {
        return delegatesByAccountId[_accountId];
    }

    /// @inheritdoc IAuth
    function getAccountIdsByDelegate(address _delegate)
        external
        view
        returns (uint128[] memory)
    {
        return accountIdsByDelegate[_delegate];
    }

    /// @inheritdoc IAuth
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

    /// @inheritdoc IAuth
    function createAccount() external returns (uint128 accountId) {
        /// @dev this auth contract will ALWAYS be the actual owner of the account
        accountId = PERPS_MARKET_PROXY.createAccount();

        /// @dev caller will be the account actor
        actorByAccountId[accountId] = msg.sender;
        accountIdsByActor[msg.sender].push(accountId);

        emit AccountCreated(accountId, msg.sender);
    }

    /// @inheritdoc IAuth
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

        emit AccountCreated(accountId, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                            ACTOR MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IAuth
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

        emit AccountActorChanged(_accountId, msg.sender, _newActor);
    }

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

    /// @inheritdoc IAuth
    function addDelegate(uint128 _accountId, address _delegate)
        external
        onlyAccountActor(_accountId)
        notZeroAddress(_delegate)
    {
        isDelegateByAccountId[_accountId][_delegate] = true;

        delegatesByAccountId[_accountId].push(_delegate);
        accountIdsByDelegate[_delegate].push(_accountId);

        emit AccountDelegateAdded(_accountId, _delegate);
    }

    /// @inheritdoc IAuth
    function removeDelegate(uint128 _accountId, address _delegate)
        external
        onlyAccountActor(_accountId)
    {
        isDelegateByAccountId[_accountId][_delegate] = false;

        _removeDelegateFromDelegatesByAccountId(_accountId, _delegate);
        _removeDelegateFromAccountIdsByDelegate(_accountId, _delegate);

        emit AccountDelegateRemoved(_accountId, _delegate);
    }

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

    /// @inheritdoc IAuth
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

        emit MarginEngineRegistered(_accountId, _marginEngine);
    }

    /// @inheritdoc IAuth
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

        emit MarginEngineUnregistered(_accountId, _marginEngine);
    }
}

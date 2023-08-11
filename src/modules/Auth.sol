// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {ERC721Receiver} from "src/tokens/ERC721Receiver.sol";
import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";

contract Auth is ERC721Receiver {
    /*//////////////////////////////////////////////////////////////
                          CONSTANTS/IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice ADMIN's have permission to do everything except for transferring account ownership
    bytes32 internal constant _ADMIN_PERMISSION = "ADMIN";

    IPerpsMarketProxy internal immutable PERPS_MARKET_PROXY;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    mapping(uint128 accountId => address accountOwner) internal ownerByAccountId;

    mapping(uint128 accountId => address[] delegates) internal
        delegatesByAccountId;

    mapping(uint128 accountId => mapping(address delegate => bool isDelegate))
        internal isDelegateByAccountId;

    mapping(address accountOwner => uint128[] accountIds) internal
        accountIdsByOwner;

    mapping(address delegate => uint128[] accountIds) internal
        accountIdsByDelegate;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error OnlyAccountOwner(uint128 accountId, address owner);
    error OnlyAccountTokenProxy(address tokenProxy);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyAccountOwner(uint128 _accountId) {
        _onlyAccountOwner(_accountId);

        _;
    }

    function _onlyAccountOwner(uint128 _accountId) internal view {
        if (ownerByAccountId[_accountId] != msg.sender) {
            revert OnlyAccountOwner(_accountId, msg.sender);
        }
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _perpsMarketProxy) {
        PERPS_MARKET_PROXY = IPerpsMarketProxy(_perpsMarketProxy);
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    function isActorAccountOwner(address _actor, uint128 _accountId)
        public
        view
        returns (bool)
    {
        return ownerByAccountId[_accountId] == _actor;
    }

    function isActorDelegate(address _actor, uint128 _accountId)
        public
        view
        returns (bool)
    {
        return isDelegateByAccountId[_accountId][_actor];
    }

    function getOwnerByAccountId(uint128 _accountId)
        external
        view
        returns (address)
    {
        return ownerByAccountId[_accountId];
    }

    function getDelegatesByAccountId(uint128 _accountId)
        external
        view
        returns (address[] memory)
    {
        return delegatesByAccountId[_accountId];
    }

    function getAccountIdsByOwner(address _accountOwner)
        external
        view
        returns (uint128[] memory)
    {
        return accountIdsByOwner[_accountOwner];
    }

    function getAccountIdsByDelegate(address _delegate)
        external
        view
        returns (uint128[] memory)
    {
        return accountIdsByDelegate[_delegate];
    }

    /*//////////////////////////////////////////////////////////////
                             CREATE ACCOUNT
    //////////////////////////////////////////////////////////////*/

    function createAccount(address _actor)
        external
        returns (uint128 accountId)
    {
        accountId = PERPS_MARKET_PROXY.createAccount();

        PERPS_MARKET_PROXY.grantPermission({
            accountId: accountId,
            permission: _ADMIN_PERMISSION,
            user: msg.sender
        });

        ownerByAccountId[accountId] = _actor;
        accountIdsByOwner[_actor].push(accountId);
    }

    /*//////////////////////////////////////////////////////////////
                           TRANSFER OWNERSHIP
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(uint128 _accountId, address _newOwner)
        external
        onlyAccountOwner(_accountId)
    {
        assert(_newOwner != address(0));

        _removeAccountIdFromAccountIdsByOwner(_accountId);

        ownerByAccountId[_accountId] = _newOwner;
        accountIdsByOwner[_newOwner].push(_accountId);
    }

    function _removeAccountIdFromAccountIdsByOwner(uint128 _accountId)
        internal
    {
        uint128[] memory accountIds = accountIdsByOwner[msg.sender];

        uint256 accountIdsLength = accountIds.length;

        for (uint256 i = 0; i < accountIdsLength;) {
            if (accountIds[i] == _accountId) {
                accountIds[i] = accountIds[accountIdsLength - 1];
                accountIdsByOwner[msg.sender] = accountIds;
                accountIdsByOwner[msg.sender].pop();
                return;
            }

            unchecked {
                ++i;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ADD DELEGATE
    //////////////////////////////////////////////////////////////*/

    function addDelegate(uint128 _accountId, address _delegate)
        external
        onlyAccountOwner(_accountId)
    {
        assert(_delegate != address(0));

        isDelegateByAccountId[_accountId][_delegate] = true;

        delegatesByAccountId[_accountId].push(_delegate);
        accountIdsByDelegate[_delegate].push(_accountId);
    }

    /*//////////////////////////////////////////////////////////////
                            REMOVE DELEGATE
    //////////////////////////////////////////////////////////////*/

    function removeDelegate(uint128 _accountId, address _delegate)
        external
        onlyAccountOwner(_accountId)
    {
        isDelegateByAccountId[_accountId][_delegate] = false;

        _removeDelegateFromDelegatesByAccountId(_accountId, _delegate);
        _removeDelegateFromAccountIdsByDelegate(_accountId, _delegate);
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
}

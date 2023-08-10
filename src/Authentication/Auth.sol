// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IAccountModule} from
    "lib/synthetix-v3/protocol/synthetix/contracts/interfaces/IAccountModule.sol";

contract Auth {
    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    IAccountModule internal immutable PERPS_MARKET_PROXY;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    mapping(uint128 accountId => address accountOwner) internal ownerByAccountId;
    mapping(uint128 accountId => address[] delegates) internal
        delegatesByAccountId;

    mapping(address accountOwner => uint128[] accountIds) internal
        accountIdsByOwner;
    mapping(address delegate => uint128[] accountIds) internal
        accountIdsByDelegate;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error OnlyAccountOwner(uint128 accountId, address owner);

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
        PERPS_MARKET_PROXY = IAccountModule(_perpsMarketProxy);
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
        address[] memory delegates = delegatesByAccountId[_accountId];

        uint256 delegatesLength = delegates.length;

        for (uint256 i = 0; i < delegatesLength;) {
            if (delegates[i] == _actor) return true;

            unchecked {
                ++i;
            }
        }

        return false;
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

    function createAccount() external returns (uint128 accountId) {
        accountId = PERPS_MARKET_PROXY.createAccount();

        ownerByAccountId[accountId] = msg.sender;
        accountIdsByOwner[msg.sender].push(accountId);
    }

    function onERC721Received(address, address, uint256, bytes memory)
        external
        pure
        returns (bytes4)
    {
        return
            bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
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

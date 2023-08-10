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
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _perpsMarketProxy) {
        PERPS_MARKET_PROXY = IAccountModule(_perpsMarketProxy);
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    function isActorAccountOwner(address actor, uint128 accountId)
        public
        view
        returns (bool)
    {
        return ownerByAccountId[accountId] == actor;
    }

    function isActorDelegate(address actor, uint128 accountId)
        public
        view
        returns (bool)
    {
        address[] memory delegates = delegatesByAccountId[accountId];

        uint256 delegatesLength = delegates.length;

        for (uint256 i = 0; i < delegatesLength;) {
            if (delegates[i] == actor) return true;

            unchecked {
                ++i;
            }
        }

        return false;
    }

    function getOwnerByAccountId(uint128 accountId)
        external
        view
        returns (address)
    {
        return ownerByAccountId[accountId];
    }

    function getDelegatesByAccountId(uint128 accountId)
        external
        view
        returns (address[] memory)
    {
        return delegatesByAccountId[accountId];
    }

    function getAccountIdsByOwner(address accountOwner)
        external
        view
        returns (uint128[] memory)
    {
        return accountIdsByOwner[accountOwner];
    }

    function getAccountIdsByDelegate(address delegate)
        external
        view
        returns (uint128[] memory)
    {
        return accountIdsByDelegate[delegate];
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

    function transferOwnership(uint128 accountId, address newOwner) external {
        assert(newOwner != address(0));

        if (ownerByAccountId[accountId] != msg.sender) {
            revert OnlyAccountOwner(accountId, msg.sender);
        }

        _removeAccountIdFromAccountIdsByOwner(accountId);

        ownerByAccountId[accountId] = newOwner;
        accountIdsByOwner[newOwner].push(accountId);
    }

    function _removeAccountIdFromAccountIdsByOwner(uint128 accountId)
        internal
    {
        uint128[] memory accountIds = accountIdsByOwner[msg.sender];

        uint256 accountIdsLength = accountIds.length;

        for (uint256 i = 0; i < accountIdsLength;) {
            if (accountIds[i] == accountId) {
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

    function addDelegate(uint128 accountId, address delegate) external {
        assert(delegate != address(0));

        if (ownerByAccountId[accountId] != msg.sender) {
            revert OnlyAccountOwner(accountId, msg.sender);
        }

        delegatesByAccountId[accountId].push(delegate);
        accountIdsByDelegate[delegate].push(accountId);
    }

    /*//////////////////////////////////////////////////////////////
                            REMOVE DELEGATE
    //////////////////////////////////////////////////////////////*/

    function removeDelegate(uint128 accountId, address delegate) external {
        if (ownerByAccountId[accountId] != msg.sender) {
            revert OnlyAccountOwner(accountId, msg.sender);
        }

        _removeDelegateFromDelegatesByAccountId(accountId, delegate);
        _removeDelegateFromAccountIdsByDelegate(accountId, delegate);
    }

    function _removeDelegateFromDelegatesByAccountId(
        uint128 accountId,
        address delegate
    ) internal {
        address[] memory delegates = delegatesByAccountId[accountId];

        uint256 delegatesLength = delegates.length;

        for (uint256 i = 0; i < delegatesLength;) {
            if (delegates[i] == delegate) {
                delegates[i] = delegates[delegatesLength - 1];
                delegatesByAccountId[accountId] = delegates;
                delegatesByAccountId[accountId].pop();
                return;
            }

            unchecked {
                ++i;
            }
        }
    }

    function _removeDelegateFromAccountIdsByDelegate(
        uint128 accountId,
        address delegate
    ) internal {
        uint128[] memory accountIds = accountIdsByDelegate[delegate];

        uint256 accountIdsLength = accountIds.length;

        for (uint256 i = 0; i < accountIdsLength;) {
            if (accountIds[i] == accountId) {
                accountIds[i] = accountIds[accountIdsLength - 1];
                accountIdsByDelegate[delegate] = accountIds;
                accountIdsByDelegate[delegate].pop();
                return;
            }

            unchecked {
                ++i;
            }
        }
    }
}

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

    mapping(uint128 accountId => address accountOwner) public ownerByAccountId;
    mapping(uint128 accountId => address[] delegates) public
        delegatesByAccountId;

    mapping(address accountOwner => uint128[] accountIds) public
        accountIdsByOwner;
    mapping(address delegate => uint128[] accountIds) public
        accountIdsByDelegate;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error OnlyAccountOwner(uint128 accountId, address owner);
    error OnlyAccountDelegateOrOwner(uint128 accountId, address delegate);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _perpsMarketProxy) {
        PERPS_MARKET_PROXY = IAccountModule(_perpsMarketProxy);
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    function isCallerAccountOwner(uint128 accountId)
        public
        view
        returns (bool)
    {
        return ownerByAccountId[accountId] == msg.sender;
    }

    function isCallerDelegate(uint128 accountId) public view returns (bool) {
        address[] memory delegates = delegatesByAccountId[accountId];

        uint256 delegatesLength = delegates.length;

        for (uint256 i = 0; i < delegatesLength;) {
            if (delegates[i] == msg.sender) return true;

            unchecked {
                ++i;
            }
        }

        return false;
    }

    /*//////////////////////////////////////////////////////////////
                             CREATE ACCOUNT
    //////////////////////////////////////////////////////////////*/

    function createAccount() external {
        uint128 accountId = PERPS_MARKET_PROXY.createAccount();

        ownerByAccountId[accountId] = msg.sender;
        accountIdsByOwner[msg.sender].push(accountId);
    }

    /*//////////////////////////////////////////////////////////////
                           TRANSFER OWNERSHIP
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(uint128 accountId, address newOwner) external {
        if (!isCallerAccountOwner(accountId)) {
            revert OnlyAccountOwner(accountId, msg.sender);
        }

        _removeAccountIdFromAccountIdsByOwner(accountId);

        ownerByAccountId[accountId] = newOwner;
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
        if (!isCallerAccountOwner(accountId)) {
            revert OnlyAccountOwner(accountId, msg.sender);
        }
        delegatesByAccountId[accountId].push(delegate);
        accountIdsByDelegate[delegate].push(accountId);
    }

    /*//////////////////////////////////////////////////////////////
                            REMOVE DELEGATE
    //////////////////////////////////////////////////////////////*/

    function removeDelegate(uint128 accountId, address delegate) external {
        if (!isCallerAccountOwner(accountId)) {
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

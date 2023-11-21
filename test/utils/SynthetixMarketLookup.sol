// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

contract SynthetixMarketLookup {
    mapping(string => uint128) public spotMarketCache;
    mapping(string => uint128) public perpsMarketCache;

    error NotFound(string name);
    error GetMarketsFailed(address proxy);

    function findPerpsMarketId(string memory name, address proxy)
        public
        returns (uint128)
    {
        if (perpsMarketCache[name] != 0) {
            return perpsMarketCache[name];
        }

        (bool s, bytes memory result) =
            proxy.call(abi.encodeWithSignature("getMarkets()"));
        if (s) {
            uint128[] memory marketIds = abi.decode(result, (uint128[]));
            uint128 id = _findMarketId(name, proxy, marketIds);
            perpsMarketCache[name] = id;
        } else {
            revert GetMarketsFailed(proxy);
        }

        revert NotFound(name);
    }

    function findSpotMarketId(string memory name, address proxy)
        public
        returns (uint128)
    {
        if (spotMarketCache[name] != 0) {
            return spotMarketCache[name];
        }

        (bool s, bytes memory result) =
            proxy.call(abi.encodeWithSignature("getSynths()"));
        if (s) {
            uint128[] memory marketIds = abi.decode(result, (uint128[]));
            uint128 id = _findMarketId(name, proxy, marketIds);
            spotMarketCache[name] = id;
        } else {
            revert GetMarketsFailed(proxy);
        }

        revert NotFound(name);
    }

    function _findMarketId(
        string memory name,
        address proxy,
        uint128[] memory marketIds
    ) internal returns (uint128) {
        for (uint128 i = 0; i <= marketIds.length; i++) {
            (bool s, bytes memory result) =
                proxy.call(abi.encodeWithSignature("name(uint128)", i));

            if (s) {
                string memory _name = abi.decode(result, (string));
                if (_compare(_name, name)) {
                    return i;
                }
            }
        }

        revert NotFound(name);
    }

    function _compare(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}

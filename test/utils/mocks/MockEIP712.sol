// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../src/utils/EIP712.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockEIP712 is EIP712 {
    uint256 public immutable _cachedThis;
    uint256 public immutable _cachedChainId;
    bytes32 public immutable _cachedNameHash;
    bytes32 public immutable _cachedVersionHash;
    bytes32 public immutable _cachedDomainSeparator;

    constructor() {
        _cachedThis = uint256(uint160(address(this)));
        _cachedChainId = block.chainid;

        (string memory name, string memory version) = _domainNameAndVersion();
        bytes32 nameHash = keccak256(bytes(name));
        bytes32 versionHash = keccak256(bytes(version));
        _cachedNameHash = nameHash;
        _cachedVersionHash = versionHash;

        bytes32 separator;
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Load the free memory pointer.
            mstore(m, _DOMAIN_TYPEHASH)
            mstore(add(m, 0x20), nameHash)
            mstore(add(m, 0x40), versionHash)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            separator := keccak256(m, 0xa0)
        }
        _cachedDomainSeparator = separator;
    }

    function hashTypedData(bytes32 structHash)
        external
        view
        returns (bytes32)
    {
        return _hashTypedData(structHash);
    }

    /// @dev Returns the EIP-712 domain separator.
    function buildDomainSeparator() public view returns (bytes32 separator) {
        // We will use `separator` to store the name hash to save a bit of gas.
        separator = _cachedNameHash;
        bytes32 versionHash = _cachedVersionHash;
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Load the free memory pointer.
            mstore(m, _DOMAIN_TYPEHASH)
            mstore(add(m, 0x20), separator)
            mstore(add(m, 0x40), versionHash)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            separator := keccak256(m, 0xa0)
        }
    }

    /// @dev Returns if the cached domain separator has been invalidated.
    function cachedDomainSeparatorInvalidated()
        public
        view
        returns (bool result)
    {
        uint256 cachedChainId = _cachedChainId;
        uint256 cachedThis = _cachedThis;
        /// @solidity memory-safe-assembly
        assembly {
            result :=
                iszero(and(eq(chainid(), cachedChainId), eq(address(), cachedThis)))
        }
    }
}

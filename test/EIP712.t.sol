// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {Test} from "lib/forge-std/src/Test.sol";
import {EIP712} from "src/utils/EIP712.sol";
import {MockEIP712} from "./utils/mocks/MockEIP712.sol";
import {RandomSigner} from "./utils/RandomSigner.sol";

contract EIP712Test is Test, RandomSigner, EIP712 {
    MockEIP712 mock;

    function setUp() public {
        mock = new MockEIP712();
    }

    function test_domainNameAndVersion() public pure {
        (string memory name, string memory version) = _domainNameAndVersion();
        assert(
            keccak256(abi.encodePacked(name))
                == keccak256(abi.encodePacked("SMv3: OrderBook"))
        );
        assert(
            keccak256(abi.encodePacked(version))
                == keccak256(abi.encodePacked("1"))
        );
    }

    function test_DOMAIN_SEPARATOR() public {
        bytes32 expectedDomainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("SMv3: OrderBook"),
                keccak256("1"),
                block.chainid,
                address(mock)
            )
        );
        assertEq(mock.DOMAIN_SEPARATOR(), expectedDomainSeparator);
    }

    function test_hashTypedData() public {
        (address signer, uint256 privateKey) = _randomSigner();

        (address to,) = _randomSigner();

        string memory message = "Test SMv3";

        bytes32 structHash = keccak256(
            abi.encode("Message(address to,string message)", to, message)
        );
        bytes32 expectedDigest = keccak256(
            abi.encodePacked("\x19\x01", mock.DOMAIN_SEPARATOR(), structHash)
        );

        assertEq(mock.hashTypedData(structHash), expectedDigest);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, expectedDigest);

        address recoveredAddress = ecrecover(expectedDigest, v, r, s);

        assertEq(recoveredAddress, signer);
    }

    struct _testEIP5267Variables {
        bytes1 fields;
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
        bytes32 salt;
        uint256[] extensions;
    }

    function test_eip712Domain() public {
        _testEIP5267Variables memory t;
        (
            t.fields,
            t.name,
            t.version,
            t.chainId,
            t.verifyingContract,
            t.salt,
            t.extensions
        ) = mock.eip712Domain();

        assertEq(t.fields, hex"0f");
        assertEq(t.name, "SMv3: OrderBook");
        assertEq(t.version, "1");
        assertEq(t.chainId, block.chainid);
        assertEq(t.verifyingContract, address(mock));
        assertEq(t.salt, bytes32(0));
        assertEq(t.extensions, new uint256[](0));
    }

    function test_buildDomainSeparator() public {
        bytes32 separator = mock.buildDomainSeparator();
        assertEq(separator, mock._cachedDomainSeparator());
    }

    function test_cachedDomainSeparatorInvalidated() public {
        assertFalse(mock.cachedDomainSeparatorInvalidated());
    }
}

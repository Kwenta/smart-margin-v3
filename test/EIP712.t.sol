// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {Test} from "lib/forge-std/src/Test.sol";
import {EIP712} from "src/utils/EIP712.sol";

contract EIP712Test is Test, EIP712 {
    function test_constructor() public pure {
        /// @custom:write-test-here
        assert(true);
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

    function test_DOMAIN_SEPARATOR() public pure {
        /// @custom:write-test-here
        assert(true);
    }

    function test_hashTypedData() public pure {
        /// @custom:write-test-here
        assert(true);
    }

    function test_eip712Domain() public pure {
        /// @custom:write-test-here
        assert(true);
    }

    function test_buildDomainSeparator() public pure {
        /// @custom:write-test-here
        assert(true);
    }

    function test_cachedDomainSeparatorInvalidated() public pure {
        /// @custom:write-test-here
        assert(true);
    }

    /// @custom:reference github.com/Vectorized/solady/blob/main/test/EIP712.t.sol
}

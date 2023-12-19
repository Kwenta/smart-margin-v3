// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {Test} from "lib/forge-std/src/Test.sol";
import {SignatureCheckerLib} from "src/libraries/SignatureCheckerLib.sol";

contract SignatureCheckerLibTest is Test {
    /// @dev following test is an example of how to use the library; no functionality is tested
    function test_isValidSignatureNowCalldata(
        address signer,
        bytes32 hash,
        bytes calldata signature
    ) public view {
        bool isValid = SignatureCheckerLib.isValidSignatureNowCalldata({
            signer: signer,
            hash: hash,
            signature: signature
        });
        assert(isValid == true || isValid == false);
    }

    /// @custom:reference github.com/Vectorized/solady/blob/main/test/SignatureCheckerLib.t.sol
}

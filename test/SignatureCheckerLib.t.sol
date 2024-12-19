// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

import {Test} from "lib/forge-std/src/Test.sol";
import {SignatureCheckerLib} from "src/libraries/SignatureCheckerLib.sol";
import {RandomSigner} from "./utils/RandomSigner.sol";

contract SignatureCheckerLibTest is Test, RandomSigner {
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
    function testSignatureChecker(bytes32 digest) public {
        (address signer, uint256 privateKey) = _randomSigner();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        if (_random() % 8 == 0) {
            assertEq(
                this.isValidSignatureNowCalldata(
                    signer, digest, abi.encodePacked(r, s, v)
                ),
                true
            );
        }

        if (_random() % 8 == 0) {
            bytes32 vs;
            /// @solidity memory-safe-assembly
            assembly {
                vs := or(shl(255, sub(v, 27)), s)
            }
            assertEq(
                this.isValidSignatureNowCalldata(
                    signer, digest, abi.encode(r, vs)
                ),
                true
            );
        }

        if (_random() % 8 == 0) {
            bytes32 vsc; // Corrupted `vs`.
            /// @solidity memory-safe-assembly
            assembly {
                vsc := or(shl(255, xor(1, sub(v, 27))), s)
            }
            assertEq(
                this.isValidSignatureNowCalldata(
                    signer, digest, abi.encode(r, vsc)
                ),
                false
            );
        }

        if (_random() % 8 == 0) {
            uint8 vc = uint8(_random()); // Corrupted `v`.
            while (vc == 28 || vc == 27) vc = uint8(_random());
            assertEq(
                this.isValidSignatureNowCalldata(
                    signer, digest, abi.encodePacked(r, s, vc)
                ),
                false
            );
        }
    }

    function isValidSignatureNowCalldata(
        address signer,
        bytes32 hash,
        bytes calldata signature
    ) external view returns (bool result) {
        result = SignatureCheckerLib.isValidSignatureNowCalldata(
            signer, hash, signature
        );
    }
}

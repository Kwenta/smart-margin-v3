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
    function testSignatureChecker(bytes32 digest) public {
        (address signer, uint256 privateKey) = _randomSigner();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        if (_random() % 8 == 0) {
            assertEq(
                this.isValidSignatureNowCalldata(signer, digest, abi.encodePacked(r, s, v)), true
            );
        }

        if (_random() % 8 == 0) {
            bytes32 vs;
            /// @solidity memory-safe-assembly
            assembly {
                vs := or(shl(255, sub(v, 27)), s)
            }
            assertEq(this.isValidSignatureNowCalldata(signer, digest, abi.encode(r, vs)), true);
        }

        if (_random() % 8 == 0) {
            bytes32 vsc; // Corrupted `vs`.
            /// @solidity memory-safe-assembly
            assembly {
                vsc := or(shl(255, xor(1, sub(v, 27))), s)
            }
            assertEq(this.isValidSignatureNowCalldata(signer, digest, abi.encode(r, vsc)), false);
        }

        if (_random() % 8 == 0) {
            uint8 vc = uint8(_random()); // Corrupted `v`.
            while (vc == 28 || vc == 27) vc = uint8(_random());
            assertEq(
                this.isValidSignatureNowCalldata(signer, digest, abi.encodePacked(r, s, vc)), false
            );
        }
    }

    function isValidSignatureNowCalldata(address signer, bytes32 hash, bytes calldata signature)
        external
        view
        returns (bool result)
    {
        result = SignatureCheckerLib.isValidSignatureNowCalldata(signer, hash, signature);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               SIGNATURE CHECKING TEST UTILS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns a pseudorandom random number from [0 .. 2**256 - 1] (inclusive).
    /// For usage in fuzz tests, please ensure that the function has an unnamed uint256 argument.
    /// e.g. `testSomething(uint256) public`.
    function _random() internal returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // This is the keccak256 of a very long string I randomly mashed on my keyboard.
            let sSlot := 0xd715531fe383f818c5f158c342925dcf01b954d24678ada4d07c36af0f20e1ee
            let sValue := sload(sSlot)

            mstore(0x20, sValue)
            r := keccak256(0x20, 0x40)

            // If the storage is uninitialized, initialize it to the keccak256 of the calldata.
            if iszero(sValue) {
                sValue := sSlot
                let m := mload(0x40)
                calldatacopy(m, 0, calldatasize())
                r := keccak256(m, calldatasize())
            }
            sstore(sSlot, add(r, 1))

            // Do some biased sampling for more robust tests.
            // prettier-ignore
            for {} 1 {} {
                let d := byte(0, r)
                // With a 1/256 chance, randomly set `r` to any of 0,1,2.
                if iszero(d) {
                    r := and(r, 3)
                    break
                }
                // With a 1/2 chance, set `r` to near a random power of 2.
                if iszero(and(2, d)) {
                    // Set `t` either `not(0)` or `xor(sValue, r)`.
                    let t := xor(not(0), mul(iszero(and(4, d)), not(xor(sValue, r))))
                    // Set `r` to `t` shifted left or right by a random multiple of 8.
                    switch and(8, d)
                    case 0 {
                        if iszero(and(16, d)) { t := 1 }
                        r := add(shl(shl(3, and(byte(3, r), 0x1f)), t), sub(and(r, 7), 3))
                    }
                    default {
                        if iszero(and(16, d)) { t := shl(255, 1) }
                        r := add(shr(shl(3, and(byte(3, r), 0x1f)), t), sub(and(r, 7), 3))
                    }
                    // With a 1/2 chance, negate `r`.
                    if iszero(and(0x20, d)) { r := not(r) }
                    break
                }
                // Otherwise, just set `r` to `xor(sValue, r)`.
                r := xor(sValue, r)
                break
            }
        }
    }

    /// @dev Returns a random signer and its private key.
    function _randomSigner() internal returns (address signer, uint256 privateKey) {
        uint256 privateKeyMax = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140;
        privateKey = _hem(_random(), 1, privateKeyMax);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0xffa18649) // `addr(uint256)`.
            mstore(0x20, privateKey)
            if iszero(call(gas(), 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D, 0, 0x1c, 0x24, 0x00, 0x20)) { revert(0, 0) }
            signer := mload(0x00)
        }
    }

    /// @dev Adapted from `bound`:
    /// https://github.com/foundry-rs/forge-std/blob/ff4bf7db008d096ea5a657f2c20516182252a3ed/src/StdUtils.sol#L10
    /// Differentially fuzzed tested against the original implementation.
    function _hem(uint256 x, uint256 min, uint256 max)
        internal
        pure
        virtual
        returns (uint256 result)
    {
        require(min <= max, "Max is less than min.");

        /// @solidity memory-safe-assembly
        assembly {
            // prettier-ignore
            for {} 1 {} {
                // If `x` is between `min` and `max`, return `x` directly.
                // This is to ensure that dictionary values
                // do not get shifted if the min is nonzero.
                // More info: https://github.com/foundry-rs/forge-std/issues/188
                if iszero(or(lt(x, min), gt(x, max))) {
                    result := x
                    break
                }

                let size := add(sub(max, min), 1)
                if and(iszero(gt(x, 3)), gt(size, x)) {
                    result := add(min, x)
                    break
                }

                let w := not(0)
                if and(iszero(lt(x, sub(0, 4))), gt(size, sub(w, x))) {
                    result := sub(max, sub(w, x))
                    break
                }

                // Otherwise, wrap x into the range [min, max],
                // i.e. the range is inclusive.
                if iszero(lt(x, max)) {
                    let d := sub(x, max)
                    let r := mod(d, size)
                    if iszero(r) {
                        result := max
                        break
                    }
                    result := add(add(min, r), w)
                    break
                }
                let d := sub(min, x)
                let r := mod(d, size)
                if iszero(r) {
                    result := min
                    break
                }
                result := add(sub(max, r), 1)
                break
            }
        }
    }
}

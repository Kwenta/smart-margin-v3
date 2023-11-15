// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {EIP7412} from "src/utils/EIP7412.sol";
import {SynthetixMock} from "test/utils/mocks/SynthetixMock.sol";
import {Test} from "lib/forge-std/src/Test.sol";

contract EIP7412Test is Test, SynthetixMock {
    function test_fulfillOracleQuery(bytes calldata signedOffchainData)
        public
    {
        address payable mock_eip7412_implementer = payable(address(0xE19));

        mock_fulfillOracleQuery(mock_eip7412_implementer, signedOffchainData);

        EIP7412 eip7412 = new EIP7412();

        uint256 preBalance = address(this).balance;

        (bool success,) = address(eip7412).call{value: 5 wei}(
            abi.encodeWithSelector(
                EIP7412.fulfillOracleQuery.selector,
                mock_eip7412_implementer,
                signedOffchainData
            )
        );

        assertTrue(success);
        assertLt(address(this).balance, preBalance);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

// foundry
import {Test} from "lib/forge-std/src/Test.sol";

// synthetix v3
import {ICoreProxy} from "src/interfaces/synthetix/ICoreProxy.sol";

// tokens
import {IERC20} from "src/interfaces/tokens/IERC20.sol";

// constants
import {Constants} from "test/utils/Constants.sol";
import {OPTIMISM_GOERLI_CORE_PROXY} from
    "script/utils/parameters/OptimismGoerliParameters.sol";

contract SUSDHelper is Test, Constants {
    // synthetix v3
    ICoreProxy coreProxy = ICoreProxy(OPTIMISM_GOERLI_CORE_PROXY);

    function mint(address target, uint256 amount) public {
        address sUSD = coreProxy.getUsdToken();
        deal(sUSD, target, amount);
    }
}

contract Mint is SUSDHelper {
    function test_mint() public {
        mint(address(this), AMOUNT);
        IERC20 sUSD = IERC20(coreProxy.getUsdToken());
        uint256 balance = IERC20(sUSD).balanceOf(address(this));
        assertEq(balance, AMOUNT);
    }
}

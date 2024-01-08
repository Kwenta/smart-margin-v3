// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {Bootstrap, Engine} from "test/utils/Bootstrap.sol";
import {IEngine} from "src/interfaces/IEngine.sol";
import {MockEngineUpgrade} from "test/utils/mocks/MockEngineUpgrade.sol";

contract UpgradeTest is Bootstrap {
    function setUp() public {
        vm.rollFork(BASE_BLOCK_NUMBER);
        initializeBase();
    }
}

contract MockUpgrade is UpgradeTest {
    MockEngineUpgrade mockEngineUpgrade;

    function deployMockEngine() internal {
        mockEngineUpgrade = new MockEngineUpgrade(
            address(perpsMarketProxy),
            address(spotMarketProxy),
            address(sUSD),
            address(pDAO),
            address(USDC),
            sUSDCId
        );
    }

    function test_upgrade() public {
        string memory message = "hi";

        bool success;
        bytes memory response;

        (success,) = address(engine).call(
            abi.encodeWithSelector(MockEngineUpgrade.echo.selector, message)
        );
        assert(!success);

        deployMockEngine();

        vm.prank(pDAO);

        engine.upgradeToAndCall(address(mockEngineUpgrade), "");

        (success, response) = address(engine).call(
            abi.encodeWithSelector(MockEngineUpgrade.echo.selector, message)
        );
        assert(success);
        assertEq(abi.decode(response, (string)), message);
    }

    function test_upgrade_nonce_state(uint256 nonce) public {
        /// @dev alter nonce state
        uint256 wordPos = uint248(nonce >> 8);
        uint256 bitPos = uint8(nonce);
        uint256 mask = 1 << bitPos;

        vm.prank(ACTOR);

        engine.invalidateUnorderedNonces(accountId, wordPos, mask);

        bool hasBeenUsed = engine.hasUnorderedNonceBeenUsed({
            _accountId: accountId,
            _nonce: nonce
        });

        /// @dev assert that nonce modification was successfully observed
        assertTrue(hasBeenUsed);

        deployMockEngine();

        vm.prank(pDAO);

        /// @dev upgrade engine
        engine.upgradeToAndCall(address(mockEngineUpgrade), "");

        hasBeenUsed = engine.hasUnorderedNonceBeenUsed({
            _accountId: accountId,
            _nonce: nonce
        });

        /// @dev assert nonce state is unchanged
        assertTrue(hasBeenUsed);
    }

    function test_upgrade_credit_state(uint256 amount) public {
        /// @dev alter credit state
        vm.assume(amount > 0);
        vm.assume(amount <= sUSD.balanceOf(ACTOR));

        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), amount);

        uint256 preEngineBalance = sUSD.balanceOf(address(engine));
        uint256 preActorBalance = sUSD.balanceOf(ACTOR);

        engine.creditAccount(accountId, amount);

        uint256 postEngineBalance = sUSD.balanceOf(address(engine));
        uint256 postActorBalance = sUSD.balanceOf(ACTOR);

        vm.stopPrank();

        /// @dev assert that credit modification was successfully observed
        assert(postEngineBalance == preEngineBalance + amount);
        assert(postActorBalance == preActorBalance - amount);

        deployMockEngine();

        vm.prank(pDAO);

        /// @dev upgrade engine
        engine.upgradeToAndCall(address(mockEngineUpgrade), "");

        /// @dev assert credit state is unchanged
        assert(postEngineBalance == preEngineBalance + amount);
        assert(postActorBalance == preActorBalance - amount);
    }

    function test_upgrade_only_pDAO() public {
        deployMockEngine();

        vm.prank(BAD_ACTOR);

        vm.expectRevert(abi.encodeWithSelector(IEngine.OnlyPDAO.selector));

        engine.upgradeToAndCall(address(mockEngineUpgrade), "");
    }
}

/// @custom:write-future-engine-upgrade-tests-here
contract UpgradeEngineV2 is UpgradeTest {}

contract RemoveUpgradability is UpgradeTest {
    function test_removeUpgradability() public {
        MockEngineUpgrade mockEngineUpgrade = new MockEngineUpgrade(
            address(perpsMarketProxy),
            address(spotMarketProxy),
            address(sUSD),
            address(0), // set pDAO to zero address to effectively remove upgradability
            address(USDC),
            sUSDCId
        );

        vm.prank(pDAO);

        engine.upgradeToAndCall(address(mockEngineUpgrade), "");

        vm.prank(pDAO);

        vm.expectRevert(abi.encodeWithSelector(IEngine.NonUpgradeable.selector));

        engine.upgradeToAndCall(address(mockEngineUpgrade), "");
    }
}

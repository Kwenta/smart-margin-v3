// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Bootstrap} from "test/utils/Bootstrap.sol";
import {ConditionalOrderSignature} from
    "test/utils/ConditionalOrderSignature.sol";
import {IEngine} from "src/interfaces/IEngine.sol";

contract NonceBitmapTest is Bootstrap, ConditionalOrderSignature {
    address signer;
    uint256 signerPrivateKey;

    function setUp() public {
        vm.rollFork(GOERLI_BLOCK_NUMBER);
        initializeOptimismGoerli();

        signerPrivateKey = 0x12341234;
        signer = vm.addr(signerPrivateKey);

        synthMinter.mint_sUSD(signer, AMOUNT);

        vm.startPrank(signer);

        accountId = perpsMarketProxy.createAccount();

        perpsMarketProxy.grantPermission({
            accountId: accountId,
            permission: ADMIN_PERMISSION,
            user: address(engine)
        });

        sUSD.approve(address(engine), type(uint256).max);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: int256(AMOUNT)
        });

        vm.stopPrank();
    }

    function test_invalidateUnorderedNonces() public {
        uint256 nonce = 1;
        uint256 mask = type(uint256).max;

        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: 1 ether,
            settlementStrategyId: 0,
            acceptablePrice: type(uint256).max,
            isReduceOnly: false,
            trackingCode: TRACKING_CODE,
            referrer: REFERRER
        });

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: nonce,
            requireVerified: false,
            trustedExecutor: address(this),
            maxExecutorFee: type(uint256).max,
            conditions: new bytes[](0)
        });

        bytes memory signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        bool canExec = engine.canExecute(co, signature, ZERO_CO_FEE);

        assertTrue(canExec);

        vm.prank(signer);

        engine.invalidateUnorderedNonces(accountId, uint248(nonce >> 8), mask);

        canExec = engine.canExecute(co, signature, ZERO_CO_FEE);

        assertFalse(canExec);
    }

    function test_hasUnorderedNonceBeenUsed() public {
        uint256 nonce = 1;
        uint256 mask = type(uint256).max;

        bool hasBeenUsed = engine.hasUnorderedNonceBeenUsed({
            _accountId: accountId,
            _nonce: nonce
        });

        assertFalse(hasBeenUsed);

        vm.prank(signer);

        engine.invalidateUnorderedNonces(accountId, uint248(nonce >> 8), mask);

        hasBeenUsed = engine.hasUnorderedNonceBeenUsed({
            _accountId: accountId,
            _nonce: nonce
        });

        assertTrue(hasBeenUsed);
    }

    function test_invalidateUnorderedNonces_Only_Owner_Delegate() public {
        uint256 nonce = 1;
        uint256 mask = type(uint256).max;

        vm.prank(signer);

        engine.invalidateUnorderedNonces(accountId, uint248(nonce >> 8), mask);

        bool hasBeenUsed = engine.hasUnorderedNonceBeenUsed({
            _accountId: accountId,
            _nonce: nonce
        });

        assertTrue(hasBeenUsed);

        nonce = 2;

        vm.prank(signer);

        perpsMarketProxy.grantPermission({
            accountId: accountId,
            permission: PERPS_COMMIT_ASYNC_ORDER_PERMISSION,
            user: NEW_ACTOR
        });

        vm.prank(NEW_ACTOR);

        engine.invalidateUnorderedNonces(accountId, uint248(nonce >> 8), mask);

        hasBeenUsed = engine.hasUnorderedNonceBeenUsed({
            _accountId: accountId,
            _nonce: nonce
        });

        assertTrue(hasBeenUsed);
    }

    function test_fuzz_invalidateUnorderedNonces(uint256 nonce) public {
        uint256 wordPos = uint248(nonce >> 8);
        uint256 bitPos = uint8(nonce);
        uint256 mask = 1 << bitPos;

        vm.prank(signer);

        engine.invalidateUnorderedNonces(accountId, wordPos, mask);

        bool hasBeenUsed = engine.hasUnorderedNonceBeenUsed({
            _accountId: accountId,
            _nonce: nonce
        });

        assertTrue(hasBeenUsed);
    }
}

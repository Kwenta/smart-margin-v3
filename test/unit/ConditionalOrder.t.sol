// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Bootstrap, IPerpsMarketProxy} from "test/utils/Bootstrap.sol";
import {ConditionalOrderSignature} from
    "test/utils/ConditionalOrderSignature.sol";
import {IEngine} from "src/interfaces/IEngine.sol";
import {PythMock} from "test/utils/mocks/PythMock.sol";

contract ConditionalOrderTest is
    Bootstrap,
    ConditionalOrderSignature,
    PythMock
{
    address signer;
    uint256 signerPrivateKey;
    address bad_signer;
    uint256 bad_signerPrivateKey;

    function setUp() public {
        vm.rollFork(GOERLI_BLOCK_NUMBER);
        initializeOptimismGoerli();

        signerPrivateKey = 0x12341234;
        signer = vm.addr(signerPrivateKey);

        bad_signerPrivateKey = 0x12341235;
        bad_signer = vm.addr(bad_signerPrivateKey);

        synthMinter.mint_sUSD(signer, AMOUNT);

        vm.startPrank(signer);
        accountId = perpsMarketProxy.createAccount();

        perpsMarketProxy.grantPermission({
            accountId: accountId,
            permission: "ADMIN",
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
}

contract CanExecute is ConditionalOrderTest {
    function test_canExecute() public {
        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: 1 ether,
            settlementStrategyId: 0,
            acceptablePrice: type(uint256).max
        });

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: 0,
            requireVerified: false,
            trustedExecutor: address(this),
            conditions: new bytes[](0)
        });

        bytes memory signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        bool canExec = engine.canExecute(co, signature);

        assertTrue(canExec);
    }

    /// @custom:todo canExecute verify nonce has not been executed before
    /// @custom:todo canExecute !trustedExecutor
    /// @custom:todo canExecute when account has enough gas
    /// @custom:todo canExecute when account doesnt have enough gas
}

contract VerifySigner is ConditionalOrderTest {
    function test_verifySigner() public {
        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: 0,
            accountId: accountId,
            sizeDelta: 0,
            settlementStrategyId: 0,
            acceptablePrice: 0
        });

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: 0,
            requireVerified: false,
            trustedExecutor: address(this),
            conditions: new bytes[](0)
        });

        bool isVerified = engine.verifySigner(co);

        assertTrue(isVerified);
    }

    function test_verifySigner_false() public {
        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: 0,
            accountId: accountId,
            sizeDelta: 0,
            settlementStrategyId: 0,
            acceptablePrice: 0
        });

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: BAD_ACTOR,
            nonce: 0,
            requireVerified: false,
            trustedExecutor: address(this),
            conditions: new bytes[](0)
        });

        bool isVerified = engine.verifySigner(co);

        assertFalse(isVerified);
    }
}

contract VerifySignature is ConditionalOrderTest {
    function test_verifySignature() public {
        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: 0,
            accountId: 0,
            sizeDelta: 0,
            settlementStrategyId: 0,
            acceptablePrice: 0
        });

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: 0,
            requireVerified: false,
            trustedExecutor: address(this),
            conditions: new bytes[](0)
        });

        bytes memory signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        bool isVerified = engine.verifySignature(co, signature);

        assertTrue(isVerified);
    }

    function test_verifySignature_false() public {
        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: 0,
            accountId: 0,
            sizeDelta: 0,
            settlementStrategyId: 0,
            acceptablePrice: 0
        });

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: 0,
            requireVerified: false,
            trustedExecutor: address(this),
            conditions: new bytes[](0)
        });

        bytes memory signature = getConditionalOrderSignature({
            co: co,
            privateKey: bad_signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        bool isVerified = engine.verifySignature(co, signature);

        assertFalse(isVerified);
    }

    /// @custom:todo canExecute !verifySignature(): no replay after signature is used
}

contract VerifyConditions is ConditionalOrderTest {
    function test_verifyCondtionalOrder_verified() public {
        bytes[] memory conditions = new bytes[](1);
        conditions[0] = isTimestampAfter(0);

        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: 0,
            accountId: 0,
            sizeDelta: 0,
            settlementStrategyId: 0,
            acceptablePrice: 0
        });

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: 0,
            requireVerified: false,
            trustedExecutor: address(this),
            conditions: conditions
        });

        bool isVerified = engine.verifyConditions(co);

        assertTrue(isVerified);
    }

    function test_verifyCondtionalOrder_not_verified() public {
        bytes[] memory conditions = new bytes[](1);
        conditions[0] = isTimestampAfter(type(uint256).max);

        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: 0,
            accountId: 0,
            sizeDelta: 0,
            settlementStrategyId: 0,
            acceptablePrice: 0
        });

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: 0,
            requireVerified: false,
            trustedExecutor: address(this),
            conditions: conditions
        });

        bool isVerified = engine.verifyConditions(co);

        assertFalse(isVerified);
    }
}

contract Execute is ConditionalOrderTest {
    int64 constant MOCK_ETH_PRICE = 166_441_377_332;
    uint64 constant MOCK_ETH_CONF = 136_840_497;
    int32 constant MOCK_ETH_EXPO = -8; // 166441377332 == 1664.41377332 USD

    function test_execute_order_committed() public {
        mock_pyth_getPrice({
            pyth: address(pyth),
            id: pythPriceFeedIdEthUsd,
            price: MOCK_ETH_PRICE,
            conf: MOCK_ETH_CONF,
            expo: MOCK_ETH_EXPO
        });

        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: 1 ether,
            settlementStrategyId: 0,
            acceptablePrice: type(uint256).max
        });

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: 0,
            requireVerified: false,
            trustedExecutor: address(this),
            conditions: new bytes[](0)
        });

        bytes memory signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        (IPerpsMarketProxy.Data memory retOrder, uint256 fees) =
            engine.execute(co, signature);

        assertTrue(retOrder.settlementTime != 0);
        assertTrue(retOrder.request.marketId == SETH_PERPS_MARKET_ID);
        assertTrue(retOrder.request.accountId == accountId);
        assertTrue(retOrder.request.sizeDelta == 1 ether);
        assertTrue(retOrder.request.settlementStrategyId == 0);
        assertTrue(retOrder.request.acceptablePrice == type(uint256).max);
        assertTrue(retOrder.request.trackingCode == TRACKING_CODE);
        assertTrue(retOrder.request.referrer == REFERRER);
    }

    /// @custom:todo test when order committed results in error (exceeds leverage after fee taken by executor)
    /// @custom:todo test when order committed results in error (other edge cases)
    /// @custom:todo test error CannotExecuteOrder()
}

contract Fee is ConditionalOrderTest {
    int64 constant MOCK_ETH_PRICE = 166_441_377_332;
    uint64 constant MOCK_ETH_CONF = 136_840_497;
    int32 constant MOCK_ETH_EXPO = -8; // 166441377332 == 1664.41377332 USD

    function test_fee_imposed() public {
        mock_pyth_getPrice({
            pyth: address(pyth),
            id: pythPriceFeedIdEthUsd,
            price: MOCK_ETH_PRICE,
            conf: MOCK_ETH_CONF,
            expo: MOCK_ETH_EXPO
        });

        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: 1 ether,
            settlementStrategyId: 0,
            acceptablePrice: type(uint256).max
        });

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: 0,
            requireVerified: false,
            trustedExecutor: address(this),
            conditions: new bytes[](0)
        });

        bytes memory signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        engine.execute(co, signature);

        assertEq(
            engine.getConditionalOrderFeeInUSD(), sUSD.balanceOf(address(this))
        );
    }
    /// @custom:todo test fee is not paid
    /// @custom:todo test fee is not paid because no sUSD
    /// @custom:todo test fee paid results in error (exceeds leverage after fee taken by executor)
}

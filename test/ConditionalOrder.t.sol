// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Bootstrap, IPerpsMarketProxy} from "test/utils/Bootstrap.sol";
import {ConditionalOrderSignature} from
    "test/utils/ConditionalOrderSignature.sol";
import {IEngine} from "src/interfaces/IEngine.sol";
import {PythMock} from "test/utils/mocks/PythMock.sol";
import {SynthetixMock} from "test/utils/mocks/SynthetixMock.sol";

contract ConditionalOrderTest is
    Bootstrap,
    ConditionalOrderSignature,
    PythMock,
    SynthetixMock
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
}

contract CanExecute is ConditionalOrderTest {
    function test_canExecute_true() public {
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

    function test_canExecute_false_nonce_used() public {
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

        // nonce is now used; cannot execute again
        bool canExec = engine.canExecute(co, signature);

        assertFalse(canExec);
    }

    function test_canExecute_false_trusted_executor() public {
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

        vm.prank(BAD_ACTOR);

        bool canExec = engine.canExecute(co, signature);

        assertFalse(canExec);
    }
}

contract VerifySigner is ConditionalOrderTest {
    function test_verifySigner() public {
        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: 0,
            accountId: accountId,
            sizeDelta: 0,
            settlementStrategyId: 0,
            acceptablePrice: 0,
            isReduceOnly: false,
            trackingCode: TRACKING_CODE,
            referrer: REFERRER
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
            acceptablePrice: 0,
            isReduceOnly: false,
            trackingCode: TRACKING_CODE,
            referrer: REFERRER
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
            acceptablePrice: 0,
            isReduceOnly: false,
            trackingCode: TRACKING_CODE,
            referrer: REFERRER
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

    function test_verifySignature_false_private_key() public {
        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: 0,
            accountId: 0,
            sizeDelta: 0,
            settlementStrategyId: 0,
            acceptablePrice: 0,
            isReduceOnly: false,
            trackingCode: TRACKING_CODE,
            referrer: REFERRER
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
}

contract VerifyConditions is ConditionalOrderTest {
    function test_max_condition_size_exceeded() public {
        bytes[] memory conditions = new bytes[](6); // exceeds max size of 5

        IEngine.OrderDetails memory orderDetails;

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: 0,
            requireVerified: true,
            trustedExecutor: address(0),
            conditions: conditions
        });

        vm.expectRevert(
            abi.encodeWithSelector(IEngine.MaxConditionSizeExceeded.selector)
        );

        engine.verifyConditions(co);
    }

    function test_verify_conditions_verified() public {
        int64 mock_price = 173_078_000_000;
        bytes32 mock_assetId = PYTH_ETH_USD_ASSET_ID;
        mock_pyth_getPrice({
            pyth: address(pyth),
            id: mock_assetId,
            price: mock_price,
            conf: 45_999_999,
            expo: -8
        });

        bytes[] memory conditions = new bytes[](5);
        conditions[0] = isTimestampAfter(0);
        conditions[1] = isTimestampBefore(type(uint256).max);
        conditions[2] = isPriceAbove(PYTH_ETH_USD_ASSET_ID, 0);
        conditions[3] = isPriceBelow(PYTH_ETH_USD_ASSET_ID, type(int64).max);
        conditions[4] = isMarketOpen(SETH_PERPS_MARKET_ID);

        IEngine.OrderDetails memory orderDetails;

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: 0,
            requireVerified: true,
            trustedExecutor: address(0),
            conditions: conditions
        });

        bool isVerified = engine.verifyConditions(co);

        assertTrue(isVerified);
    }

    function test_verify_conditions_not_verified() public {
        int64 mock_price = 173_078_000_000;
        bytes32 mock_assetId = PYTH_ETH_USD_ASSET_ID;
        mock_pyth_getPrice({
            pyth: address(pyth),
            id: mock_assetId,
            price: mock_price,
            conf: 45_999_999,
            expo: -8
        });

        bytes[] memory conditions = new bytes[](5);
        conditions[0] = isTimestampAfter(0);
        conditions[1] = isTimestampBefore(type(uint256).max);
        conditions[2] = isPriceAbove(PYTH_ETH_USD_ASSET_ID, 0);
        conditions[3] = isPriceBelow(PYTH_ETH_USD_ASSET_ID, 0); // false
        conditions[4] = isMarketOpen(SETH_PERPS_MARKET_ID);

        IEngine.OrderDetails memory orderDetails;

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: 0,
            requireVerified: true,
            trustedExecutor: address(0),
            conditions: conditions
        });

        bool isVerified = engine.verifyConditions(co);

        assertFalse(isVerified);
    }

    function test_verifyConditions_public_non_condition_isAccountDelegate()
        public
    {
        bytes[] memory conditions = new bytes[](1);
        conditions[0] = abi.encodeWithSelector(
            IEngine.isAccountDelegate.selector, accountId, address(engine)
        );

        IEngine.OrderDetails memory orderDetails;

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: 0,
            requireVerified: true,
            trustedExecutor: address(0),
            conditions: conditions
        });

        bool isVerified = engine.verifyConditions(co);

        assertTrue(isVerified);
    }

    function test_verifyConditions_external_non_condition_getAccountStats()
        public
    {
        bytes[] memory conditions = new bytes[](1);
        conditions[0] =
            abi.encodeWithSelector(IEngine.getAccountStats.selector, accountId);

        IEngine.OrderDetails memory orderDetails;

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: 0,
            requireVerified: true,
            trustedExecutor: address(0),
            conditions: conditions
        });

        bool isVerified = engine.verifyConditions(co);

        assertFalse(isVerified);
    }

    function test_verifyConditions_internal_non_condition_getSynthAddress()
        public
    {
        bytes[] memory conditions = new bytes[](1);
        conditions[0] = abi.encodeWithSignature(
            "_getSynthAddress(uint128 _synthMarketId)", SETH_SPOT_MARKET_ID
        );

        IEngine.OrderDetails memory orderDetails;

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: 0,
            requireVerified: true,
            trustedExecutor: address(0),
            conditions: conditions
        });

        bool isVerified = engine.verifyConditions(co);

        assertFalse(isVerified);
    }

    function test_verifyConditions_modify_state_createAccount() public {
        bytes[] memory conditions = new bytes[](1);
        conditions[0] = abi.encodeWithSignature("createAccount()");

        IEngine.OrderDetails memory orderDetails;

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: 0,
            requireVerified: true,
            trustedExecutor: address(0),
            conditions: conditions
        });

        bool isVerified = engine.verifyConditions(co);

        assertFalse(isVerified);
    }
}

contract Execute is ConditionalOrderTest {
    function test_execute_order_committed() public {
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

        (
            IPerpsMarketProxy.Data memory retOrder,
            uint256 fees,
            uint256 conditionalOrderFee
        ) = engine.execute(co, signature);

        // retOrder
        assertTrue(retOrder.settlementTime != 0);
        assertTrue(retOrder.request.marketId == SETH_PERPS_MARKET_ID);
        assertTrue(retOrder.request.accountId == accountId);
        assertTrue(retOrder.request.sizeDelta == 1 ether);
        assertTrue(retOrder.request.settlementStrategyId == 0);
        assertTrue(retOrder.request.acceptablePrice == type(uint256).max);
        assertTrue(retOrder.request.trackingCode == TRACKING_CODE);
        assertTrue(retOrder.request.referrer == REFERRER);

        // fees
        assertTrue(fees != 0);

        // conditionalOrderFee
        assertTrue(conditionalOrderFee != 0);
    }

    function test_execute_leverage_exceeded() public {
        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: 50 ether,
            settlementStrategyId: 0,
            acceptablePrice: type(uint256).max,
            isReduceOnly: false,
            trackingCode: TRACKING_CODE,
            referrer: REFERRER
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

        (uint256 orderFees,) = perpsMarketProxy.computeOrderFees({
            marketId: SETH_PERPS_MARKET_ID,
            sizeDelta: 50 ether
        });

        uint256 requiredMargin = perpsMarketProxy.requiredMarginForOrder(
            accountId, SETH_PERPS_MARKET_ID, 50 ether
        );

        uint256 marginPostConditionalOrderFee = AMOUNT
            - (orderFees = orderFees * engine.FEE_SCALING_FACTOR() / 10_000);

        vm.expectRevert(
            abi.encodeWithSelector(
                InsufficientMargin.selector,
                marginPostConditionalOrderFee,
                requiredMargin
            )
        );

        engine.execute(co, signature);
    }

    function test_execute_CannotExecuteOrder() public {
        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: 50 ether,
            settlementStrategyId: 0,
            acceptablePrice: type(uint256).max,
            isReduceOnly: false,
            trackingCode: TRACKING_CODE,
            referrer: REFERRER
        });

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: address(0),
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

        vm.expectRevert(
            abi.encodeWithSelector(IEngine.CannotExecuteOrder.selector)
        );

        engine.execute(co, signature);
    }
}

contract Fee is ConditionalOrderTest {
    function test_fee_imposed() public {
        assertEq(0, sUSD.balanceOf(address(this)));

        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: 10 ether,
            settlementStrategyId: 0,
            acceptablePrice: type(uint256).max,
            isReduceOnly: false,
            trackingCode: TRACKING_CODE,
            referrer: REFERRER
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

        (,, uint256 conditionalOrderFee) = engine.execute(co, signature);

        assertEq(sUSD.balanceOf(address(this)), conditionalOrderFee);
    }

    function test_fee_imposed_at_upper_fee_cap() public {
        uint256 mocked_order_fees =
            engine.UPPER_FEE_CAP() * engine.FEE_SCALING_FACTOR();

        mock_computeOrderFees({
            perpsMarketProxy: address(perpsMarketProxy),
            marketId: SETH_PERPS_MARKET_ID,
            sizeDelta: 1 ether,
            orderFees: mocked_order_fees,
            fillPrice: 1 ether
        });

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

        (,, uint256 conditionalOrderFee) = engine.execute(co, signature);

        assertEq(engine.UPPER_FEE_CAP(), conditionalOrderFee);
        assertEq(engine.UPPER_FEE_CAP(), sUSD.balanceOf(address(this)));
    }

    function test_fee_imposed_above_upper_fee_cap() public {
        uint256 mocked_order_fees =
            engine.UPPER_FEE_CAP() * (engine.FEE_SCALING_FACTOR() + 1);

        mock_computeOrderFees({
            perpsMarketProxy: address(perpsMarketProxy),
            marketId: SETH_PERPS_MARKET_ID,
            sizeDelta: 1 ether,
            orderFees: mocked_order_fees,
            fillPrice: 1 ether
        });

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

        (,, uint256 conditionalOrderFee) = engine.execute(co, signature);

        assertEq(engine.UPPER_FEE_CAP(), conditionalOrderFee);
        assertEq(engine.UPPER_FEE_CAP(), sUSD.balanceOf(address(this)));
    }

    function test_fee_imposed_below_upper_fee_cap() public {
        uint256 mocked_order_fees = engine.UPPER_FEE_CAP();

        mock_computeOrderFees({
            perpsMarketProxy: address(perpsMarketProxy),
            marketId: SETH_PERPS_MARKET_ID,
            sizeDelta: 1 ether,
            orderFees: mocked_order_fees,
            fillPrice: 1 ether
        });

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

        (,, uint256 conditionalOrderFee) = engine.execute(co, signature);

        assertEq(
            (engine.UPPER_FEE_CAP() * engine.FEE_SCALING_FACTOR()) / 10_000,
            conditionalOrderFee
        );
        assertEq(
            (engine.UPPER_FEE_CAP() * engine.FEE_SCALING_FACTOR()) / 10_000,
            sUSD.balanceOf(address(this))
        );
    }

    function test_fee_imposed_below_lower_fee_cap() public {
        uint256 mocked_order_fees = 0;

        mock_computeOrderFees({
            perpsMarketProxy: address(perpsMarketProxy),
            marketId: SETH_PERPS_MARKET_ID,
            sizeDelta: 1 ether,
            orderFees: mocked_order_fees,
            fillPrice: 1 ether
        });

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

        (,, uint256 conditionalOrderFee) = engine.execute(co, signature);

        assertEq(engine.LOWER_FEE_CAP(), conditionalOrderFee);
        assertEq(engine.LOWER_FEE_CAP(), sUSD.balanceOf(address(this)));
    }

    function test_fee_imposed_fee_cannot_be_paid() public {
        vm.prank(signer);

        engine.modifyCollateral({
            _accountId: accountId,
            _synthMarketId: SUSD_SPOT_MARKET_ID,
            _amount: -int256(AMOUNT)
        });

        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: 10 ether,
            settlementStrategyId: 0,
            acceptablePrice: type(uint256).max,
            isReduceOnly: false,
            trackingCode: TRACKING_CODE,
            referrer: REFERRER
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

        (uint256 orderFees,) = perpsMarketProxy.computeOrderFees({
            marketId: SETH_PERPS_MARKET_ID,
            sizeDelta: 10 ether
        });

        orderFees = orderFees * engine.FEE_SCALING_FACTOR() / 10_000;

        vm.expectRevert(
            abi.encodeWithSelector(
                InsufficientCollateralAvailableForWithdraw.selector,
                0,
                orderFees
            )
        );

        engine.execute(co, signature);
    }

    function test_fee_imposed_insufficient_collateral_for_order() public {
        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: 50 ether,
            settlementStrategyId: 0,
            acceptablePrice: type(uint256).max,
            isReduceOnly: false,
            trackingCode: TRACKING_CODE,
            referrer: REFERRER
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

        (uint256 orderFees,) = perpsMarketProxy.computeOrderFees({
            marketId: SETH_PERPS_MARKET_ID,
            sizeDelta: 50 ether
        });

        uint256 requiredMargin = perpsMarketProxy.requiredMarginForOrder(
            accountId, SETH_PERPS_MARKET_ID, 50 ether
        );

        uint256 marginPostConditionalOrderFee = AMOUNT
            - (orderFees = orderFees * engine.FEE_SCALING_FACTOR() / 10_000);

        vm.expectRevert(
            abi.encodeWithSelector(
                InsufficientMargin.selector,
                marginPostConditionalOrderFee,
                requiredMargin
            )
        );

        engine.execute(co, signature);
    }
}

contract ReduceOnly is ConditionalOrderTest {
    function test_reduce_only() public {
        mock_getOpenPosition(
            address(perpsMarketProxy), accountId, SETH_PERPS_MARKET_ID, -1 ether
        );

        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: 1 ether,
            settlementStrategyId: 0,
            acceptablePrice: type(uint256).max,
            isReduceOnly: true,
            trackingCode: TRACKING_CODE,
            referrer: REFERRER
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

        (, uint256 fees,) = engine.execute(co, signature);

        // confirms that the reduce-only order was executed
        assertTrue(fees > 0);
    }

    function test_reduce_only_zero_size() public {
        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: 1 ether,
            settlementStrategyId: 0,
            acceptablePrice: type(uint256).max,
            isReduceOnly: true,
            trackingCode: TRACKING_CODE,
            referrer: REFERRER
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

        (, uint256 fees, uint256 conditionalOrderFee) =
            engine.execute(co, signature);

        assertEq(0, fees);
        assertEq(0, conditionalOrderFee);
    }

    function test_reduce_only_same_sign() public {
        mock_getOpenPosition(
            address(perpsMarketProxy), accountId, SETH_PERPS_MARKET_ID, 1 ether
        );

        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: 1 ether,
            settlementStrategyId: 0,
            acceptablePrice: type(uint256).max,
            isReduceOnly: true,
            trackingCode: TRACKING_CODE,
            referrer: REFERRER
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

        (, uint256 fees, uint256 conditionalOrderFee) =
            engine.execute(co, signature);

        assertEq(0, fees);
        assertEq(0, conditionalOrderFee);
    }

    function test_reduce_only_truncate_size_down() public {
        mock_getOpenPosition(
            address(perpsMarketProxy), accountId, SETH_PERPS_MARKET_ID, -1 ether
        );

        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: type(int128).max,
            settlementStrategyId: 0,
            acceptablePrice: type(uint256).max,
            isReduceOnly: true,
            trackingCode: TRACKING_CODE,
            referrer: REFERRER
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

        (, uint256 fees,) = engine.execute(co, signature);

        // confirms that the reduce-only order was executed
        /// @dev max sizeDelta used proves prices was truncated
        assertTrue(fees > 0);
    }

    function test_reduce_only_truncate_size_up() public {
        mock_getOpenPosition(
            address(perpsMarketProxy), accountId, SETH_PERPS_MARKET_ID, 1 ether
        );

        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: -type(int128).max,
            settlementStrategyId: 0,
            acceptablePrice: 0,
            isReduceOnly: true,
            trackingCode: TRACKING_CODE,
            referrer: REFERRER
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

        (, uint256 fees,) = engine.execute(co, signature);

        // confirms that the reduce-only order was executed
        /// @dev max sizeDelta used proves prices was truncated
        assertTrue(fees > 0);
    }
}

contract Conditions is ConditionalOrderTest {
    function test_isTimestampAfter() public {
        bool isAfter = engine.isTimestampAfter(block.timestamp - 1);
        assertTrue(isAfter);

        isAfter = engine.isTimestampAfter(block.timestamp);
        assertFalse(isAfter);

        isAfter = engine.isTimestampAfter(block.timestamp + 1);
        assertFalse(isAfter);
    }

    function test_isTimestampBefore() public {
        bool isBefore = engine.isTimestampBefore(block.timestamp - 1);
        assertFalse(isBefore);

        isBefore = engine.isTimestampBefore(block.timestamp);
        assertFalse(isBefore);

        isBefore = engine.isTimestampBefore(block.timestamp + 1);
        assertTrue(isBefore);
    }

    function test_isPriceAbove() public {
        int64 mock_price = 173_078_000_000;
        bytes32 mock_assetId = PYTH_ETH_USD_ASSET_ID;
        mock_pyth_getPrice({
            pyth: address(pyth),
            id: mock_assetId,
            price: 173_078_000_000,
            conf: 45_999_999,
            expo: -8
        });

        bool isAbove = engine.isPriceAbove(mock_assetId, mock_price - 1);
        assertTrue(isAbove);

        isAbove = engine.isPriceAbove(mock_assetId, mock_price);
        assertFalse(isAbove);

        isAbove = engine.isPriceAbove(mock_assetId, mock_price + 1);
        assertFalse(isAbove);
    }

    function test_isPriceBelow() public {
        int64 mock_price = 173_078_000_000;
        bytes32 mock_assetId = PYTH_ETH_USD_ASSET_ID;
        mock_pyth_getPrice({
            pyth: address(pyth),
            id: mock_assetId,
            price: 173_078_000_000,
            conf: 45_999_999,
            expo: -8
        });

        bool isBelow = engine.isPriceBelow(mock_assetId, mock_price - 1);
        assertFalse(isBelow);

        isBelow = engine.isPriceBelow(mock_assetId, mock_price);
        assertFalse(isBelow);

        isBelow = engine.isPriceBelow(mock_assetId, mock_price + 1);
        assertTrue(isBelow);
    }

    function test_isMarketOpen() public {
        bool isOpen = engine.isMarketOpen(SETH_PERPS_MARKET_ID);
        assertTrue(isOpen);

        mock_getMaxMarketSize(
            MARKET_CONFIGURATION_MODULE, SETH_PERPS_MARKET_ID, 0
        );

        isOpen = engine.isMarketOpen(SETH_PERPS_MARKET_ID);
        assertFalse(isOpen);
    }
}

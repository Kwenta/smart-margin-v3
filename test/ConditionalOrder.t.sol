// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

import {Bootstrap} from "test/utils/Bootstrap.sol";
import {ConditionalOrderSignature} from
    "test/utils/ConditionalOrderSignature.sol";
import {IEngine} from "src/interfaces/IEngine.sol";
import {IPerpsMarketProxy} from "src/interfaces/synthetix/IPerpsMarketProxy.sol";
import {SynthetixMock} from "test/utils/mocks/SynthetixMock.sol";

contract ConditionalOrderTest is
    Bootstrap,
    ConditionalOrderSignature,
    SynthetixMock
{
    address signer;
    uint256 signerPrivateKey;
    address bad_signer;
    uint256 bad_signerPrivateKey;

    function setUp() public {
        vm.rollFork(ARBITRUM_BLOCK_NUMBER);
        initializeArbitrum();

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
    IEngine.OrderDetails public orderDetails;
    IEngine.ConditionalOrder public co;
    bytes public signature;

    function _defineConditionalOrder() internal {
        orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: SIZE_DELTA,
            settlementStrategyId: SETTLEMENT_STRATEGY_ID,
            acceptablePrice: ACCEPTABLE_PRICE_LONG,
            isReduceOnly: false,
            trackingCode: TRACKING_CODE,
            referrer: REFERRER
        });

        co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: 0,
            requireVerified: false,
            trustedExecutor: address(this),
            maxExecutorFee: type(uint256).max,
            conditions: new bytes[](0)
        });

        signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });
    }

    function test_canExecute_true() public {
        _defineConditionalOrder();

        (bool canExec,) = engine.canExecute(co, signature, ZERO_CO_FEE);

        assertTrue(canExec);
    }

    function test_canExecute_false_maxExecutorFee_exceeded() public {
        _defineConditionalOrder();

        co.maxExecutorFee = 0; // 0 max fee (i.e. any non-zero fee is too high)

        signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        // CO_FEE is non-zero, so it exceeds the maxExecutorFee
        (bool canExec,) = engine.canExecute(co, signature, CO_FEE);

        assertFalse(canExec);
    }

    function test_canExecute_false_insufficent_account_credit() public {
        _defineConditionalOrder();

        // ensure the account has no credit
        assertEq(engine.credit(accountId), 0);

        // CO_FEE is non-zero, and the account has no credit
        (bool canExec,) = engine.canExecute(co, signature, CO_FEE);

        assertFalse(canExec);
    }

    /// @custom:todo rewrite commented test with hardhat
    /// cause : InvalidFEOpcode when calling getPricesInWei on Arbitrum
    // function test_canExecute_false_nonce_used() public {
    //     _defineConditionalOrder();

    //     engine.execute(co, signature, ZERO_CO_FEE);

    //     // nonce is now used; cannot execute again
    //     (bool canExec,) = engine.canExecute(co, signature, ZERO_CO_FEE);

    //     assertFalse(canExec);
    // }

    function test_canExecute_false_invalid_signer() public {
        _defineConditionalOrder();

        co.signer = BAD_ACTOR;

        signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        (bool canExec,) = engine.canExecute(co, signature, ZERO_CO_FEE);

        assertFalse(canExec);
    }

    function test_canExecute_false_invalid_signature() public {
        _defineConditionalOrder();

        signature = getConditionalOrderSignature({
            co: co,
            privateKey: bad_signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        (bool canExec,) = engine.canExecute(co, signature, ZERO_CO_FEE);

        assertFalse(canExec);
    }

    function test_canExecute_false_trusted_executor() public {
        _defineConditionalOrder();

        vm.prank(BAD_ACTOR);

        (bool canExec,) = engine.canExecute(co, signature, ZERO_CO_FEE);

        assertFalse(canExec);
    }

    function test_canExecute_false_require_verify_condition_not_met() public {
        bytes[] memory conditions = new bytes[](1);
        conditions[0] = isTimestampAfter(block.timestamp + 100); // condition not met

        orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: SIZE_DELTA,
            settlementStrategyId: SETTLEMENT_STRATEGY_ID,
            acceptablePrice: ACCEPTABLE_PRICE_LONG,
            isReduceOnly: false,
            trackingCode: TRACKING_CODE,
            referrer: REFERRER
        });

        co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: 0,
            requireVerified: true,
            trustedExecutor: address(this),
            maxExecutorFee: type(uint256).max,
            conditions: conditions
        });

        signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        (bool canExec,) = engine.canExecute(co, signature, ZERO_CO_FEE);

        assertFalse(canExec);
    }
}

contract VerifySigner is ConditionalOrderTest {
    function test_verifySigner() public {
        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: 0,
            accountId: accountId,
            sizeDelta: 0,
            settlementStrategyId: SETTLEMENT_STRATEGY_ID,
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
            maxExecutorFee: type(uint256).max,
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
            settlementStrategyId: SETTLEMENT_STRATEGY_ID,
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
            maxExecutorFee: type(uint256).max,
            conditions: new bytes[](0)
        });

        bool isVerified = engine.verifySigner(co);

        assertFalse(isVerified);
    }
}

contract VerifySignature is ConditionalOrderTest {
    function test_verifySignature(uint256 fuzzyNonce) public {
        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: 0,
            accountId: 0,
            sizeDelta: 0,
            settlementStrategyId: SETTLEMENT_STRATEGY_ID,
            acceptablePrice: 0,
            isReduceOnly: false,
            trackingCode: TRACKING_CODE,
            referrer: REFERRER
        });

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: fuzzyNonce,
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

        bool isVerified = engine.verifySignature(co, signature);

        assertTrue(isVerified);
    }

    function test_verifySignature_false_private_key() public {
        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: 0,
            accountId: 0,
            sizeDelta: 0,
            settlementStrategyId: SETTLEMENT_STRATEGY_ID,
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
            maxExecutorFee: type(uint256).max,
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
        bytes[] memory conditions = new bytes[](100); // 100 far exceeds max

        IEngine.OrderDetails memory orderDetails;

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: 0,
            requireVerified: true,
            trustedExecutor: address(0),
            maxExecutorFee: type(uint256).max,
            conditions: conditions
        });

        vm.expectRevert(
            abi.encodeWithSelector(IEngine.MaxConditionSizeExceeded.selector)
        );

        engine.verifyConditions(co);
    }

    function test_verify_conditions_verified() public {
        mock_getOpenPosition({
            perpsMarketProxy: address(perpsMarketProxy),
            accountId: accountId,
            marketId: SETH_PERPS_MARKET_ID,
            positionSize: 1 ether
        });

        bytes[] memory conditions = new bytes[](8);
        conditions[0] = isTimestampAfter(0);
        conditions[1] = isTimestampBefore(type(uint256).max);
        conditions[2] =
            isPriceAbove({_marketId: SETH_PERPS_MARKET_ID, _price: 0, _size: 0});
        conditions[3] = isPriceBelow({
            _marketId: SETH_PERPS_MARKET_ID,
            _price: type(uint256).max,
            _size: 0
        });
        conditions[4] = isMarketOpen(SETH_PERPS_MARKET_ID);
        conditions[5] = isPositionSizeAbove(accountId, SETH_PERPS_MARKET_ID, 0);
        conditions[6] = isPositionSizeBelow(
            accountId, SETH_PERPS_MARKET_ID, type(int64).max
        );
        conditions[7] =
            isOrderFeeBelow(SETH_PERPS_MARKET_ID, 1, type(uint256).max);

        IEngine.OrderDetails memory orderDetails;

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: 0,
            requireVerified: true,
            trustedExecutor: address(0),
            maxExecutorFee: type(uint256).max,
            conditions: conditions
        });

        bool isVerified = engine.verifyConditions(co);

        assertTrue(isVerified);
    }

    function test_verify_conditions_not_verified() public {
        bytes[] memory conditions = new bytes[](5);
        conditions[0] = isTimestampAfter(0);
        conditions[1] = isTimestampBefore(type(uint256).max);
        conditions[2] =
            isPriceAbove({_marketId: SETH_PERPS_MARKET_ID, _price: 0, _size: 0});
        conditions[3] = isPriceBelow({
            _marketId: SETH_PERPS_MARKET_ID,
            _price: 0, // false; price not below 0
            _size: 0
        });
        conditions[4] = isMarketOpen(SETH_PERPS_MARKET_ID);

        IEngine.OrderDetails memory orderDetails;

        IEngine.ConditionalOrder memory co = IEngine.ConditionalOrder({
            orderDetails: orderDetails,
            signer: signer,
            nonce: 0,
            requireVerified: true,
            trustedExecutor: address(0),
            maxExecutorFee: type(uint256).max,
            conditions: conditions
        });

        bool isVerified = engine.verifyConditions(co);

        assertFalse(isVerified);
    }

    function test_verifyConditions_InvalidConditionSelector() public {
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
            maxExecutorFee: type(uint256).max,
            conditions: conditions
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                IEngine.InvalidConditionSelector.selector, bytes4(conditions[0])
            )
        );

        engine.verifyConditions(co);
    }
}

contract Execute is ConditionalOrderTest {
    event ConditionalOrderExecuted(
        IPerpsMarketProxy.Data order, uint256 synthetixFees, uint256 executorFee
    );

    function test_execute_order_committed() public {
        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: SIZE_DELTA,
            settlementStrategyId: SETTLEMENT_STRATEGY_ID,
            acceptablePrice: ACCEPTABLE_PRICE_LONG,
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
            maxExecutorFee: type(uint256).max,
            conditions: new bytes[](0)
        });

        bytes memory signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        (IPerpsMarketProxy.Data memory retOrder, uint256 fees) =
            engine.execute(co, signature, ZERO_CO_FEE);

        // retOrder
        assertTrue(retOrder.settlementTime != 0);
        assertTrue(retOrder.request.marketId == SETH_PERPS_MARKET_ID);
        assertTrue(retOrder.request.accountId == accountId);
        assertTrue(retOrder.request.sizeDelta == SIZE_DELTA);
        assertTrue(retOrder.request.settlementStrategyId == 0);
        assertTrue(retOrder.request.acceptablePrice == type(uint256).max);
        assertTrue(retOrder.request.trackingCode == TRACKING_CODE);
        assertTrue(retOrder.request.referrer == REFERRER);

        // fees
        assertTrue(fees != 0);
    }

    function test_execute_event() public {
        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: SIZE_DELTA,
            settlementStrategyId: SETTLEMENT_STRATEGY_ID,
            acceptablePrice: ACCEPTABLE_PRICE_LONG,
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
            maxExecutorFee: type(uint256).max,
            conditions: new bytes[](0)
        });

        bytes memory signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        IPerpsMarketProxy.Data memory emptyOrder;

        // only checking that the event was emitted and not the values
        vm.expectEmit(true, true, true, false);
        emit ConditionalOrderExecuted(emptyOrder, 0, 0);

        engine.execute(co, signature, ZERO_CO_FEE);
    }

    function test_execute_CannotExecuteOrder_too_leveraged() public {
        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: INVALID_SIZE_DELTA,
            settlementStrategyId: SETTLEMENT_STRATEGY_ID,
            acceptablePrice: ACCEPTABLE_PRICE_LONG,
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
            maxExecutorFee: type(uint256).max,
            conditions: new bytes[](0)
        });

        bytes memory signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        try engine.execute(co, signature, ZERO_CO_FEE) {}
        catch (bytes memory reason) {
            assertEq(bytes4(reason), InsufficientMargin.selector);
        }
    }

    function test_execute_CannotExecuteOrder_invalid_acceptablePrice() public {
        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: SIZE_DELTA,
            settlementStrategyId: SETTLEMENT_STRATEGY_ID,
            acceptablePrice: INVALID_ACCEPTABLE_PRICE_LONG,
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
            maxExecutorFee: type(uint256).max,
            conditions: new bytes[](0)
        });

        bytes memory signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        try engine.execute(co, signature, ZERO_CO_FEE) {}
        catch (bytes memory reason) {
            assertEq(bytes4(reason), AcceptablePriceExceeded.selector);
        }
    }

    function test_execute_CannotExecuteOrder_invalid_settlementStrategyId()
        public
    {
        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: SIZE_DELTA,
            settlementStrategyId: INVALID_SETTLEMENT_STRATEGY_ID,
            acceptablePrice: ACCEPTABLE_PRICE_LONG,
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
            maxExecutorFee: type(uint256).max,
            conditions: new bytes[](0)
        });

        bytes memory signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                InvalidSettlementStrategy.selector,
                INVALID_SETTLEMENT_STRATEGY_ID
            )
        );

        engine.execute(co, signature, ZERO_CO_FEE);
    }
}

contract Fee is ConditionalOrderTest {
    function creditAccount() internal {
        // prank ACTOR because this address has sUSD
        vm.startPrank(ACTOR);

        sUSD.approve(address(engine), type(uint256).max);

        engine.creditAccount(accountId, CO_FEE);

        vm.stopPrank();
    }

    function test_fee_imposed() public {
        creditAccount();

        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: SIZE_DELTA,
            settlementStrategyId: SETTLEMENT_STRATEGY_ID,
            acceptablePrice: ACCEPTABLE_PRICE_LONG,
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
            maxExecutorFee: type(uint256).max,
            conditions: new bytes[](0)
        });

        bytes memory signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        uint256 preExecutorBalance = sUSD.balanceOf(address(this));

        engine.execute(co, signature, CO_FEE);

        uint256 postExecutorBalance = sUSD.balanceOf(address(this));

        assertEq(preExecutorBalance + CO_FEE, postExecutorBalance);
    }

    function test_fee_exceeds_account_credit() public {
        creditAccount();

        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: SIZE_DELTA,
            settlementStrategyId: SETTLEMENT_STRATEGY_ID,
            acceptablePrice: ACCEPTABLE_PRICE_LONG,
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
            maxExecutorFee: type(uint256).max,
            conditions: new bytes[](0)
        });

        bytes memory signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                IEngine.CannotExecuteOrder.selector,
                IEngine.CanExecuteResponse.InsufficientCredit
            )
        );

        engine.execute(co, signature, CO_FEE + 1);
    }

    function test_fee_exceeds_maxExecutorFee() public {
        creditAccount();

        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: SIZE_DELTA,
            settlementStrategyId: SETTLEMENT_STRATEGY_ID,
            acceptablePrice: ACCEPTABLE_PRICE_LONG,
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
            maxExecutorFee: 0, // 0 max fee (i.e. any non-zero fee is too high)
            conditions: new bytes[](0)
        });

        bytes memory signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                IEngine.CannotExecuteOrder.selector,
                IEngine.CanExecuteResponse.FeeExceedsMaxExecutorFee
            )
        );

        engine.execute(co, signature, CO_FEE);
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
            sizeDelta: SIZE_DELTA,
            settlementStrategyId: SETTLEMENT_STRATEGY_ID,
            acceptablePrice: ACCEPTABLE_PRICE_LONG,
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
            maxExecutorFee: type(uint256).max,
            conditions: new bytes[](0)
        });

        bytes memory signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        (, uint256 fees) = engine.execute(co, signature, ZERO_CO_FEE);

        // confirms that the reduce-only order was executed
        assertTrue(fees > 0);
    }

    function test_reduce_only_when_position_doesnt_exist() public {
        /*
            ensure position exists; reduce only orders cannot increase position size
        */

        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: SIZE_DELTA,
            settlementStrategyId: SETTLEMENT_STRATEGY_ID,
            acceptablePrice: ACCEPTABLE_PRICE_LONG,
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
            maxExecutorFee: type(uint256).max,
            conditions: new bytes[](0)
        });

        bytes memory signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                IEngine.CannotExecuteOrder.selector,
                IEngine.CanExecuteResponse.ReduceOnlyPositionDoesNotExist
            )
        );

        engine.execute(co, signature, ZERO_CO_FEE);
    }

    function test_reduce_only_zero_size_delta() public {
        /*
            ensure incoming size delta is non-zero
        */

        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: 0, // zero sizeDelta
            settlementStrategyId: SETTLEMENT_STRATEGY_ID,
            acceptablePrice: ACCEPTABLE_PRICE_LONG,
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
            maxExecutorFee: type(uint256).max,
            conditions: new bytes[](0)
        });

        bytes memory signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                IEngine.CannotExecuteOrder.selector,
                IEngine.CanExecuteResponse.ReduceOnlyPositionDoesNotExist
            )
        );

        engine.execute(co, signature, ZERO_CO_FEE);
    }

    function test_reduce_only_same_sign() public {
        /*
           ensure incoming size delta is NOT the same sign
        */

        mock_getOpenPosition(
            address(perpsMarketProxy), accountId, SETH_PERPS_MARKET_ID, 1 ether
        );

        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: SIZE_DELTA,
            settlementStrategyId: SETTLEMENT_STRATEGY_ID,
            acceptablePrice: ACCEPTABLE_PRICE_LONG,
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
            maxExecutorFee: type(uint256).max,
            conditions: new bytes[](0)
        });

        bytes memory signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                IEngine.CannotExecuteOrder.selector,
                IEngine.CanExecuteResponse.ReduceOnlyCannotIncreasePositionSize
            )
        );

        engine.execute(co, signature, ZERO_CO_FEE);
    }

    function test_reduce_only_truncate_size_down() public {
        mock_getOpenPosition(
            address(perpsMarketProxy),
            accountId,
            SETH_PERPS_MARKET_ID,
            -SIZE_DELTA
        );

        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: type(int128).max,
            settlementStrategyId: SETTLEMENT_STRATEGY_ID,
            acceptablePrice: ACCEPTABLE_PRICE_LONG,
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
            maxExecutorFee: type(uint256).max,
            conditions: new bytes[](0)
        });

        bytes memory signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        (, uint256 fees) = engine.execute(co, signature, ZERO_CO_FEE);

        // confirms that the reduce-only order was executed
        /// @dev max sizeDelta used proves prices was truncated
        assertTrue(fees > 0);
    }

    function test_reduce_only_truncate_size_up() public {
        mock_getOpenPosition(
            address(perpsMarketProxy),
            accountId,
            SETH_PERPS_MARKET_ID,
            SIZE_DELTA
        );

        IEngine.OrderDetails memory orderDetails = IEngine.OrderDetails({
            marketId: SETH_PERPS_MARKET_ID,
            accountId: accountId,
            sizeDelta: -type(int128).max,
            settlementStrategyId: SETTLEMENT_STRATEGY_ID,
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
            maxExecutorFee: type(uint256).max,
            conditions: new bytes[](0)
        });

        bytes memory signature = getConditionalOrderSignature({
            co: co,
            privateKey: signerPrivateKey,
            domainSeparator: engine.DOMAIN_SEPARATOR()
        });

        (, uint256 fees) = engine.execute(co, signature, ZERO_CO_FEE);

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
        (, uint256 currentFillPrice) =
            perpsMarketProxy.computeOrderFees(SETH_PERPS_MARKET_ID, 0);

        bool isAbove = engine.isPriceAbove({
            _marketId: SETH_PERPS_MARKET_ID,
            _price: 0,
            _size: 0
        });
        assertTrue(isAbove);

        isAbove = engine.isPriceAbove({
            _marketId: SETH_PERPS_MARKET_ID,
            _price: currentFillPrice,
            _size: 0
        });
        assertFalse(isAbove);

        isAbove = engine.isPriceAbove({
            _marketId: SETH_PERPS_MARKET_ID,
            _price: currentFillPrice + 1,
            _size: 0
        });
        assertFalse(isAbove);

        isAbove = isAbove = engine.isPriceAbove({
            _marketId: SETH_PERPS_MARKET_ID,
            _price: currentFillPrice - 1,
            _size: 0
        });
        assertTrue(isAbove);
    }

    function test_isPriceBelow() public {
        (, uint256 currentFillPrice) =
            perpsMarketProxy.computeOrderFees(SETH_PERPS_MARKET_ID, 0);

        bool isBelow = engine.isPriceBelow({
            _marketId: SETH_PERPS_MARKET_ID,
            _price: type(uint256).max,
            _size: 0
        });
        assertTrue(isBelow);

        isBelow = engine.isPriceBelow({
            _marketId: SETH_PERPS_MARKET_ID,
            _price: currentFillPrice,
            _size: 0
        });
        assertFalse(isBelow);

        isBelow = engine.isPriceBelow({
            _marketId: SETH_PERPS_MARKET_ID,
            _price: currentFillPrice + 1,
            _size: 0
        });
        assertTrue(isBelow);

        isBelow = isBelow = engine.isPriceBelow({
            _marketId: SETH_PERPS_MARKET_ID,
            _price: currentFillPrice - 1,
            _size: 0
        });
        assertFalse(isBelow);
    }

    function test_isMarketOpen() public {
        bool isOpen = engine.isMarketOpen(SETH_PERPS_MARKET_ID);
        assertTrue(isOpen);

        mock_getMaxMarketSize(
            address(perpsMarketProxy), SETH_PERPS_MARKET_ID, 0
        );

        isOpen = engine.isMarketOpen(SETH_PERPS_MARKET_ID);
        assertFalse(isOpen);
    }

    function test_isPositionSizeAbove() public {
        int128 mock_positionSize = 1 ether;
        mock_getOpenPosition({
            perpsMarketProxy: address(perpsMarketProxy),
            accountId: accountId,
            marketId: SETH_PERPS_MARKET_ID,
            positionSize: mock_positionSize
        });

        bool isAbove = engine.isPositionSizeAbove(
            accountId, SETH_PERPS_MARKET_ID, mock_positionSize - 1
        );
        assertTrue(isAbove);

        isAbove = engine.isPositionSizeAbove(
            accountId, SETH_PERPS_MARKET_ID, mock_positionSize
        );
        assertFalse(isAbove);

        isAbove = engine.isPositionSizeAbove(
            accountId, SETH_PERPS_MARKET_ID, mock_positionSize + 1
        );
        assertFalse(isAbove);
    }

    function test_isPositionSizeBelow() public {
        int128 mock_positionSize = 1 ether;
        mock_getOpenPosition({
            perpsMarketProxy: address(perpsMarketProxy),
            accountId: accountId,
            marketId: SETH_PERPS_MARKET_ID,
            positionSize: mock_positionSize
        });

        bool isBelow = engine.isPositionSizeBelow(
            accountId, SETH_PERPS_MARKET_ID, mock_positionSize - 1
        );
        assertFalse(isBelow);

        isBelow = engine.isPositionSizeBelow(
            accountId, SETH_PERPS_MARKET_ID, mock_positionSize
        );
        assertFalse(isBelow);

        isBelow = engine.isPositionSizeBelow(
            accountId, SETH_PERPS_MARKET_ID, mock_positionSize + 1
        );
        assertTrue(isBelow);
    }

    function test_isOrderFeeBelow() public {
        int128 sizeDelta = 1 ether;
        (uint256 orderFees,) = perpsMarketProxy.computeOrderFees({
            marketId: SETH_PERPS_MARKET_ID,
            sizeDelta: sizeDelta
        });

        bool isBelow = engine.isOrderFeeBelow(
            SETH_PERPS_MARKET_ID, sizeDelta, orderFees - 1
        );
        assertFalse(isBelow);

        isBelow =
            engine.isOrderFeeBelow(SETH_PERPS_MARKET_ID, sizeDelta, orderFees);
        assertFalse(isBelow);

        isBelow = engine.isOrderFeeBelow(
            SETH_PERPS_MARKET_ID, sizeDelta, orderFees + 1
        );
        assertTrue(isBelow);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

// foundry
import {Test} from "lib/forge-std/src/Test.sol";

// modules
import {OrderBook} from "src/modules/OrderBook.sol";

// constants
import {Conditions} from "test/utils/Conditions.sol";
import {Constants} from "test/utils/Constants.sol";
import {OptimismGoerliParameters} from "script/Deploy.s.sol";

contract OrderBookTest is
    Test,
    Constants,
    Conditions,
    OptimismGoerliParameters
{
    OrderBook orderBook;

    function setUp() public {
        orderBook =
        new OrderBook(OWNER, MOCK_MARGIN_ENGINE, OPTIMISM_GOERLI_PERPS_MARKET_PROXY);
    }
}

contract VerificationTest is OrderBookTest {
    function test_verifyCondtionalOrder_verified() public {
        bytes[] memory conditions = new bytes[](1);
        conditions[0] = isTimestampAfter(0);

        OrderBook.ConditionalOrder memory co = OrderBook.ConditionalOrder({
            signer: address(0),
            nonce: 0,
            requireVerified: true,
            marketId: 0,
            accountId: 0,
            sizeDelta: 0,
            settlementStrategyId: 0,
            acceptablePrice: 0,
            conditions: conditions
        });

        bool isVerified = orderBook.verifyConditions(co);

        assertTrue(isVerified);
    }

    function test_verifyCondtionalOrder_not_verified() public {
        bytes[] memory conditions = new bytes[](1);
        conditions[0] = isTimestampAfter(type(uint256).max);

        OrderBook.ConditionalOrder memory co = OrderBook.ConditionalOrder({
            signer: address(0),
            nonce: 0,
            requireVerified: true,
            marketId: 0,
            accountId: 0,
            sizeDelta: 0,
            settlementStrategyId: 0,
            acceptablePrice: 0,
            conditions: conditions
        });

        bool isVerified = orderBook.verifyConditions(co);

        assertFalse(isVerified);
    }
}

contract ConditionsTest is OrderBookTest {}

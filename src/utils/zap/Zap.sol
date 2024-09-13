// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import {ZapErrors} from "./ZapErrors.sol";
import {ZapEvents} from "./ZapEvents.sol";
import {IERC20} from "src/interfaces/tokens/IERC20.sol";
import {ISpotMarketProxy} from "src/interfaces/synthetix/ISpotMarketProxy.sol";

/// @title Zap contract for zapping collateral in/out of Synthetix v3
/// @author JaredBorders (jaredborders@pm.me)
contract Zap is ZapErrors, ZapEvents {
    uint128 internal constant USD_SPOT_MARKET_ID = 0;

    enum Direction {
        In,
        Out
    }

    struct Tolerance {
        uint256 tolerableWrapAmount;
        uint256 tolerableSwapAmount;
    }

    struct ZapData {
        ISpotMarketProxy spotMarket;
        IERC20 collateral;
        uint128 marketId;
        uint256 amount;
        Tolerance tolerance;
        Direction direction;
        address receiver;
        address referrer;
    }

    function zap(ZapData calldata _data) external {
        _data.direction == Direction.In ? _zapIn(_data) : _zapOut(_data);
    }

    function _zapIn(ZapData calldata _data) private {
        uint256 amount = _data.amount;

        _data.collateral.transferFrom(msg.sender, address(this), amount);
        _data.collateral.approve(address(_data.spotMarket), amount);

        (amount,) = _data.spotMarket.wrap({
            marketId: _data.marketId,
            wrapAmount: amount,
            minAmountReceived: _data.tolerance.tolerableWrapAmount
        });

        IERC20 synth = IERC20(_data.spotMarket.getSynth(_data.marketId));
        synth.approve(address(_data.spotMarket), amount);

        (amount,) = _data.spotMarket.sell({
            marketId: _data.marketId,
            synthAmount: amount,
            minUsdAmount: _data.tolerance.tolerableSwapAmount,
            referrer: _data.referrer
        });

        IERC20 sUSD = IERC20(_data.spotMarket.getSynth(USD_SPOT_MARKET_ID));
        sUSD.transfer(_data.receiver, amount);
    }

    function _zapOut(ZapData calldata _data) private {
        uint256 amount = _data.amount;

        IERC20 sUSD = IERC20(_data.spotMarket.getSynth(USD_SPOT_MARKET_ID));
        sUSD.transferFrom(msg.sender, address(this), amount);

        sUSD.approve(address(_data.spotMarket), amount);
        (amount,) = _data.spotMarket.buy({
            marketId: _data.marketId,
            usdAmount: amount,
            minAmountReceived: _data.tolerance.tolerableSwapAmount,
            referrer: _data.referrer
        });

        IERC20 synth = IERC20(_data.spotMarket.getSynth(_data.marketId));
        synth.approve(address(_data.spotMarket), amount);

        (amount,) = _data.spotMarket.unwrap({
            marketId: _data.marketId,
            unwrapAmount: amount,
            minAmountReceived: _data.tolerance.tolerableWrapAmount
        });

        _data.collateral.transfer(_data.receiver, amount);
    }

    function wrap(ZapData calldata _data) external {
        uint256 amount = _data.amount;

        _data.collateral.transferFrom(msg.sender, address(this), amount);
        _data.collateral.approve(address(_data.spotMarket), amount);

        (amount,) = _data.spotMarket.wrap({
            marketId: _data.marketId,
            wrapAmount: amount,
            minAmountReceived: _data.tolerance.tolerableWrapAmount
        });

        IERC20 synth = IERC20(_data.spotMarket.getSynth(_data.marketId));
        synth.approve(address(_data.spotMarket), amount);

        synth.transfer(_data.receiver, amount);
    }

    function unwrap(ZapData calldata _data) external {
        uint256 amount = _data.amount;

        IERC20 synth = IERC20(_data.spotMarket.getSynth(_data.marketId));
        synth.approve(address(_data.spotMarket), amount);

        (amount,) = _data.spotMarket.unwrap({
            marketId: _data.marketId,
            unwrapAmount: amount,
            minAmountReceived: _data.tolerance.tolerableWrapAmount
        });

        _data.collateral.transfer(_data.receiver, amount);
    }
}

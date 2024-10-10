// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface ISpotMarket {

    struct Data {
        uint256 fixedFees;
        uint256 utilizationFees;
        int256 skewFees;
        int256 wrapperFees;
    }

    function getSynth(uint128 marketId)
        external
        view
        returns (address synthAddress);

    function wrap(
        uint128 marketId,
        uint256 wrapAmount,
        uint256 minAmountReceived
    )
        external
        returns (uint256 amountToMint, Data memory fees);

    function unwrap(
        uint128 marketId,
        uint256 unwrapAmount,
        uint256 minAmountReceived
    )
        external
        returns (uint256 returnCollateralAmount, Data memory fees);

    function buy(
        uint128 marketId,
        uint256 usdAmount,
        uint256 minAmountReceived,
        address referrer
    )
        external
        returns (uint256 synthAmount, Data memory fees);

    function sell(
        uint128 marketId,
        uint256 synthAmount,
        uint256 minUsdAmount,
        address referrer
    )
        external
        returns (uint256 usdAmountReceived, Data memory fees);

}

interface IPerpsMarket {

    function modifyCollateral(
        uint128 accountId,
        uint128 synthMarketId,
        int256 amountDelta
    )
        external;

    function renouncePermission(
        uint128 accountId,
        bytes32 permission
    )
        external;

    function isAuthorized(
        uint128 accountId,
        bytes32 permission,
        address target
    )
        external
        view
        returns (bool isAuthorized);

    function payDebt(uint128 accountId, uint256 amount) external;

    function debt(uint128 accountId)
        external
        view
        returns (uint256 accountDebt);

}

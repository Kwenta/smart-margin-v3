// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.27;

/// @dev this contract is used to mock the gas prices and L1 base fee
/// @dev this is required because this contract is used as a precompile on Arbitrum
/// and therefore needs needs to be injected into tests with vm.etch to prevent evm errors
contract ArbGasInfoMock {
    /// @notice Get gas prices. Uses the caller's preferred aggregator, or the default if
    /// the caller doesn't have a preferred one.
    /// @return return gas prices in wei
    ///        (
    ///            per L2 tx,
    ///            per L1 calldata byte
    ///            per storage allocation,
    ///            per ArbGas base,
    ///            per ArbGas congestion,
    ///            per ArbGas total
    ///        )
    function getPricesInWei()
        external
        pure
        returns (uint256, uint256, uint256, uint256, uint256, uint256)
    {
        return (10, 10, 10, 10, 10, 10);
    }

    /// @notice Get ArbOS's estimate of the L1 basefee in wei
    function getL1BaseFeeEstimate() external view returns (uint256) {
        return 10;
    }
}

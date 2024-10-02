// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface IERC20 {

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        external
        returns (bool);

}

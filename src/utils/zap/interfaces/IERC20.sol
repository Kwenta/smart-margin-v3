// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

<<<<<<< HEAD
    function allowance(address owner, address spender)
=======
    function allowance(
        address owner,
        address spender
    )
>>>>>>> 4af916b (👷 pull latest zap)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount)
        external
        returns (bool);
}

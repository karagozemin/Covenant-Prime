// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MockExchange {
    mapping(address asset => uint256 price) public prices;

    event Bought(address indexed asset, uint256 amountUSDC, address indexed recipient);
    event Sold(address indexed asset, uint256 amountAsset, address indexed recipient);

    function setPrice(address asset, uint256 price) external {
        prices[asset] = price;
    }

    function quote(address asset, uint256 amount) external view returns (uint256) {
        return amount * prices[asset] / 1e18;
    }

    function buy(address asset, uint256 amountUSDC, address recipient) external {
        emit Bought(asset, amountUSDC, recipient);
    }

    function sell(address asset, uint256 amountAsset, address recipient) external {
        emit Sold(asset, amountAsset, recipient);
    }
}

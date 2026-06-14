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
        uint256 tokenAmount = prices[asset] == 0 ? amountUSDC * 1e12 : amountUSDC * 1e18 / prices[asset];
        IMintableStock(asset).mint(recipient, tokenAmount);
        emit Bought(asset, amountUSDC, recipient);
    }

    function sell(address asset, uint256 amountAsset, address recipient) external {
        IMintableStock(asset).burn(recipient, amountAsset);
        emit Sold(asset, amountAsset, recipient);
    }
}

interface IMintableStock {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

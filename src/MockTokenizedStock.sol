// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MockTokenizedStock {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address account => uint256 amount) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event CorporateAction(bytes32 indexed actionHash, string actionType);

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) external {
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function corporateAction(string calldata actionType, bytes32 actionHash) external {
        emit CorporateAction(actionHash, actionType);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockERC20Wrapped is ERC20 {

    constructor() ERC20("wrapped eth","weth"){
        
    }
    function deposit() external payable{
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient WETH");
        _burn(msg.sender, amount);
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");
    }
}
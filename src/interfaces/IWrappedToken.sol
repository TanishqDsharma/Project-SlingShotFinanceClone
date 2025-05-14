// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


interface IWrappedToken is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}
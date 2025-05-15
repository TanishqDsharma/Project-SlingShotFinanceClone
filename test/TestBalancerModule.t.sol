// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../src/modules/BalancerModule.sol";
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console2.sol";
import "../src/Executioner.sol";
import "./mocks/MockERC20Wrapped.sol";
import "../src/interfaces/IWrappedToken.sol";

import "./mocks/MockERC20.sol";
contract TestBalancerModule is Test {



MockERC20 DAI;
MockERC20 USDC;
MockERC20Wrapped WETH;
IWrappedToken public IWETH;


address user1 = makeAddr("user1");

Executioner executioner;

function setUp() external {
    DAI = new MockERC20();
    USDC = new MockERC20();
    WETH = new MockERC20Wrapped();
    IWETH = IWrappedToken(address(WETH));
    console2.log("Address of MOCK DAI is: ", address(DAI));
    console2.log("Address of MOCK USDC is: ", address(USDC));
     console2.log("Address of MOCK WETH is: ", address(WETH));

    executioner = new Executioner(address(0),address(WETH));
    vm.deal(user1,100 ether);
    vm.startPrank(user1);
    IWETH.deposit{value: 10 ether}();
    
    vm.stopPrank();
    DAI.mint(user1, 10 ether);
    USDC.mint(user1, 10 ether);
}

function test_UserBalance() public{
    uint256 userbalance = IERC20(address(DAI)).balanceOf(user1);
    uint256 userWethBalance = IWETH.balanceOf(user1);
    assertEq(userbalance,10 ether);
    assertEq(userWethBalance, 10 ether);
}
    
}
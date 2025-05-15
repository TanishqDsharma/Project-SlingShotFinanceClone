// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../src/modules/UniswapModule.sol";
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console2.sol";
import "../src/Executioner.sol";
import "./mocks/MockERC20Wrapped.sol";
import "../src/interfaces/IWrappedToken.sol";
import "../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./mocks/MockERC20.sol";
import "../src/interfaces/ISLingShot.sol";
import "../src/Slingshot.sol";
import "../src/ModuleRegistry.sol";
import "../lib/v2-core/contracts/UniswapV2Factory.sol";


contract TestBalancerModule is Test {



MockERC20 DAI;
MockERC20 USDC;
MockERC20Wrapped WETH;
IWrappedToken public IWETH;
UniswapModule public uniswapModule;
IUniswapV2Router02 router02;
Slingshot slingshot;
ModuleRegistry moduleRegistry;
UniswapV2Factory uniswapV2Factory;


address user1 = makeAddr("user1");
address admin = makeAddr("admin");
Executioner executioner;

function setUp() external {
    DAI = new MockERC20();
    USDC = new MockERC20();
    WETH = new MockERC20Wrapped();
    IWETH = IWrappedToken(address(WETH));

    uniswapModule = new UniswapModule();
    router02 = IUniswapV2Router02(uniswapModule.getRouter());

    console2.log("Address of MOCK DAI is: ", address(DAI));
    console2.log("Address of MOCK USDC is: ", address(USDC));
    console2.log("Address of MOCK WETH is: ", address(WETH));

    executioner = new Executioner(address(0),address(WETH));
    slingshot = new Slingshot(address(admin),address(0),address(WETH));
    uniswapV2Factory = new UniswapV2Factory(address(admin));
    moduleRegistry = new ModuleRegistry(admin);
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

function test_RouterAddress() public{
    assertEq(uniswapModule.getRouter(),0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
}

function test_Swap() public{
    console2.log("User's Ether balance before swap: ",WETH.balanceOf(user1));

    console2.log("User's USDC balance before swap: ", USDC.balanceOf(user1));

       address[] memory path = new address[](2);
    path[0] = address(WETH);
    path[1] = address(USDC);

    uint256 amountIn = 5 ether;

    bytes memory encoded = abi.encodeCall(uniswapModule.swap,(amountIn,path,false));

    ISlingShot.TradeFormat[] memory trades = new ISlingShot.TradeFormat[](1);

    trades[0] = ISlingShot.TradeFormat({
        moduleAddress: address(uniswapModule),
        encodedCallData: encoded
    });
    
    vm.startPrank(admin);
    moduleRegistry.registerSwapModule(address(uniswapModule));
    vm.stopPrank();

    vm.startPrank(user1);
    WETH.approve(address(slingshot), 5 ether);
    slingshot.executeTrades(address(WETH), address(USDC), 5 ether, trades, 1);

    
}

function test_isModule() public{
    vm.startPrank(admin);
    moduleRegistry.registerSwapModule(address(uniswapModule));
    vm.stopPrank();
    assertEq(moduleRegistry.isModule(address(uniswapModule)),true);
}


}
// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./IUniswapModule.sol";

/// @title Slingshot Uniswap Module
contract UniswapModule is IUniswapModule {

    // @audit harcoded router address 
    function getRouter() override public pure returns (address) {
        return 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./interfaces/ISLingShot.sol";
import "./interfaces/IWrappedToken.sol";
import "./lib/ConcatStrings.sol";

contract Executioner is ISlingShot, Ownable, ConcatStrings {
    
    using SafeERC20 for IERC20;

    /// @notice Native token address (e.g., ETH, MATIC)
    address public immutable nativeToken;

    /// @notice Wrapped native token contract (e.g., WETH, WMATIC)
    IWrappedToken public immutable wrappedNativeToken;

    constructor(address _nativeToken, address _wrappedNative) Ownable(msg.sender){
        nativeToken=_nativeToken;
        wrappedNativeToken=IWrappedToken(_wrappedNative);
    }

    /**
     * @notice  Executes multi-hop trades to get the best result
     * @param trades Takes array of trades that includes moduleAddress and encodedCallData
     */

    function executeTrades(TradeFormat[] calldata trades) external onlyOwner{
        
        // Looping through the trades array
        for(uint256 i=0;i<trades.length;i++){
            // delegatecall executes code from another contract, in the context of the current contract.
            (bool success, bytes memory data) = trades[i].moduleAddress
                .delegatecall(trades[i].encodedCallData);
            
            // Dynamic error message
            require(success, appendString(string(data), 
                appendUint(string("Executioner: swap failed: "), i)));

        }
    }

    /**
     * @notice In an unlikely scenario of tokens being send to this contract allow admin to rescue them.
     * @param token Address of the token
     * @param to  Address of the receiver
     * @param amount Amount of token
     */
    function rescueTokens(address token, address to, uint256 amount) external onlyOwner(){
        if(token==nativeToken){
            (bool success,) = to.call{value: amount}("");
            require(success,"Executioner: ETH rescue failed.");
        }else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    function sendFunds(address token, address to, uint256 amount) external onlyOwner(){
        if(token==nativeToken){
             wrappedNativeToken.withdraw(amount);
             (bool success,) = to.call{value:amount}("");

        }else{
             IERC20(token).safeTransfer(to, amount);

        }
    }

    receive() external payable {}

}
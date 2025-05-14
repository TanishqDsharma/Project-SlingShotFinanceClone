// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;


import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ISLingShot.sol";
import "./interfaces/IWrappedToken.sol";
import "./Adminable.sol";
import "./ModuleRegistry.sol";
import "./ApprovalHandler.sol";
import "./Executioner.sol";


contract Slingshot is ISlingShot,Adminable,ConcatStrings,ReentrancyGuard{

    using SafeERC20 for IERC20;
    using SafeERC20 for IWrappedToken;

    /// @dev address of native token, if you are trading ETH on Ethereum,
    ///      matic on Matic etc you should use this address as token from
    address public immutable nativeToken;
    /// @dev address of wrapped native token, for Ethereum it's WETH, for Matic is wmatic etc
    IWrappedToken public immutable wrappedNativeToken;
    Executioner public immutable executioner;

    ModuleRegistry public moduleRegistry;
    ApprovalHandler public approvalHandler;

    ////////////////////////
    /////// Events /////////
    ////////////////////////


    event Trades(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address indexed recipient);

    event NewModuleRegistry(address oldRegistry, address newRegistry);
    event NewApprovalHandler(address oldApprovalHandler, address approvalHandler);

    constructor(address _admin, address _nativeToken, address _wrappedNativeToken){
        executioner = new Executioner(_nativeToken,_wrappedNativeToken);
        _setUpAdmin(_admin);
        nativeToken=_nativeToken;
        wrappedNativeToken=IWrappedToken(_wrappedNativeToken);
    }

    function executeTrades(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        TradeFormat[] calldata trades,
        uint256 finalAmountMin
    ) external nonReentrant payable{
        require(finalAmountMin>0,"Slingshot: finalAmountMin cannot be zero");
        require(trades.length>0,"Slingshot: trades cannot be empty");

        for(uint256 i=0;i<trades.length;i++){
            require(moduleRegistry.isModule(trades[i].moduleAddress), "Slingshot: not a module");

        }
        uint256 initialBalance = _getTokenBalance(toToken);
        _transferFromOrWrap(fromToken, _msgSender(), fromAmount);
        executioner.executeTrades(trades);

        uint finalBalance;
        if(toToken==nativeToken){
            finalBalance = _getTokenBalance(address(wrappedNativeToken));
        }else{
            finalBalance = _getTokenBalance(toToken);
        }

        uint finalOutputAmount = finalBalance - initialBalance;

        emit Trades(fromToken, toToken, fromAmount, finalOutputAmount, _msgSender());

        // Send to msg.sender.
        executioner.sendFunds(toToken, _msgSender(), finalOutputAmount);


    }

    /// @notice Sets ApprovalHandler that is used to transfer token from users
    /// @param _approvalHandler The address of ApprovalHandler
    // @audit emit before setting
    function setApprovalHandler(address _approvalHandler) external onlyAdmin {
        emit NewApprovalHandler(address(approvalHandler), _approvalHandler);
        approvalHandler = ApprovalHandler(_approvalHandler);
    }

    /// @notice Sets module registry used to verify modules
    /// @param _moduleRegistry The address of module registry
    function setModuleRegistry(address _moduleRegistry) external onlyAdmin {
        address oldRegistry = address(moduleRegistry);
        moduleRegistry = ModuleRegistry(_moduleRegistry);
        emit NewModuleRegistry(oldRegistry, _moduleRegistry);
    }

    /// @notice In an unlikely scenario of tokens being send to this contract
    ///         allow admin to rescue them.
    /// @param token The address of the token to rescue
    /// @param to The address of recipient
    /// @param amount The amount of the token to rescue
    function rescueTokens(address token, address to, uint256 amount) external onlyAdmin {
        if (token == nativeToken) {
            (bool success, ) = to.call{value: amount}("");
            require(success, "Slingshot: ETH rescue failed.");
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    /// @notice In an unlikely scenario of tokens being send to this contract
    ///         allow admin to rescue them.
    /// @param token The address of the token to rescue
    /// @param to The address of recipient
    /// @param amount The amount of the token to rescue
    function rescueTokensFromExecutioner(address token, address to, uint256 amount) external onlyAdmin {
        executioner.rescueTokens(token, to, amount);
    }


    function _transferFromOrWrap(address fromToken, address from, uint256 amount) internal {
        if(fromToken==nativeToken){
            require(msg.value == amount, "Slingshot: incorrect ETH value");
            wrappedNativeToken.deposit{value: amount}();
            wrappedNativeToken.safeTransfer(address(executioner), amount);  
        }else{
            approvalHandler.transferFrom(fromToken, from, address(executioner), amount);
        }
    }


    /// @notice Returns balance of the token
    /// @param token The address of the token
    /// @return balance of the token (ERC20 and native)
    function _getTokenBalance(address token) internal view returns (uint256) {
        //@audit zero address check for tokenAddress is missing
        if (token == nativeToken) {
            return address(executioner).balance;
        } else {
            return IERC20(token).balanceOf(address(executioner));
        }
    }

    /// @notice Sends token funds. For native token, it unwraps wrappedNativeToken
    /// @param token The address of the token to send
    /// @param to The address of recipient
    /// @param amount The amount of the token to send
    function _sendFunds(address token, address to, uint256 amount) internal {
        executioner.sendFunds(token, to, amount);
        if (token == nativeToken) {
            wrappedNativeToken.withdraw(amount);
            (bool success, ) = to.call{value: amount}("");
            require(success, "Slingshot: ETH Transfer failed.");
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    receive() external payable {}


}
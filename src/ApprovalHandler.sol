// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Adminable.sol";

contract ApprovalHandler is Adminable{
    using SafeERC20 for IERC20;

    bytes32 public constant SLINGSHOT_CONTRACT_ROLE = keccak256("SLINGSHOT_CONTRACT_ROLE");

    modifier onlySlingShot() {
        require(isSlingShot(_msgSender()),"Adminable: not a SLINGSHOT_CONTRACT_ROLE");
        _;
    }

    constructor(address _admin){
        _setUpAdmin(_admin);
        /**
         * The admin of the SLINGSHOT_CONTRACT_ROLE is SLINGSHOT_ADMIN_ROLE. Only accounts with the SLINGSHOT_ADMIN_ROLE 
           can grant or revoke the SLINGSHOT_CONTRACT_ROLE.
         */
        _setRoleAdminInternal(SLINGSHOT_CONTRACT_ROLE, SLINGSHOT_ADMIN_ROLE);
    }

    function isSlingShot(address _slingshot) public view returns(bool){
        return hasRole(SLINGSHOT_CONTRACT_ROLE, _slingshot);
    } 

    function grantSlingShot(address _slingshot) external{
        grantRole(SLINGSHOT_CONTRACT_ROLE, _slingshot);
    }

    function transferFrom(address fromToken, address sender, address to, uint256 amount)
        external
        onlySlingShot
    {
        IERC20(fromToken).safeTransferFrom(sender, to, amount);
    }

}
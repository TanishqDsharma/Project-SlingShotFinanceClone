// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./Adminable.sol";
import "./modules/ISlingshotModule.sol";

contract ModuleRegistry is Adminable {

    // @notice mapping to track modules
    mapping(address=>bool) public modulesIndex;

    // @notice slingshot contract address
    address public slingshot;

 
    ///////////////////
    ////// events /////
    ////////////////// 

    event ModuleRegistered(address ModuleAddress);
    event ModuleUnRegistered(address ModuleAddress);
    event NewSlingshot(address oldAddress, address newAddress);

    /**
     * 
     * @param _admin address to control admin functions
     */
    constructor(address _admin){
        _setUpAdmin(_admin);
    }

    function isModule(address _moduleAddress) public returns(bool){
        return modulesIndex[_moduleAddress];
    }
    
    function registerSwapModule(address _moduleAddress) public onlyAdmin{
        require(!modulesIndex[_moduleAddress],"Module Already Exists");
        modulesIndex[_moduleAddress] = true;
        emit ModuleRegistered(_moduleAddress); 
    }

    function registerSwapModuleBatch(address[] memory _moduleAddresses) external onlyAdmin{
        for(uint256 i=0; i<_moduleAddresses.length;i++){
            registerSwapModule(_moduleAddresses[i]);
        }
    }

    function unregisterSwapModule(address _moduleAddress) public onlyAdmin{
        require(modulesIndex[_moduleAddress]==true,"Module does not Exists");
        modulesIndex[_moduleAddress] = false;
        emit ModuleUnRegistered(_moduleAddress);
    }

    function unregisterSwapModuleBatch(address[] memory _moduleAddresses) public onlyAdmin{
        for(uint i=0;i<_moduleAddresses.length;i++){
            unregisterSwapModule(_moduleAddresses[i]);
        }
    }

    // @notice SlingShot address implementation
    function setSlingShot(address _slingshot) external onlyAdmin{
        require(slingshot!=address(0),"Zero Address");
        require(slingshot!=_slingshot,"Old and New SlingShot address are same");
        address oldAddress = slingshot;
        slingshot=_slingshot;
        emit NewSlingshot(oldAddress, _slingshot);
    }
}          
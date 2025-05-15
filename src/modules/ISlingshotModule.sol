// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

/// @title Slingshot Abstract Module
/// @dev   the only purpose of this is to allow for easy verification when adding new module
abstract contract ISlingshotModule {
    function slingshotPing() public pure returns (bool) {
        return true;
    }
}
      
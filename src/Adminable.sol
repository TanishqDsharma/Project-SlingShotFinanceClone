// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";




contract Adminable is AccessControl {

    bytes32 public constant SLINGSHOT_ADMIN_ROLE = keccak256("SLINGSHOT_ADMIN_ROLE");

    // Mapping override to allow internal role admin setting (if really needed)
    mapping(bytes32 => bytes32) private _roleAdmins;

    modifier onlyAdmin() {
        require(hasRole(SLINGSHOT_ADMIN_ROLE,_msgSender()),"Adminable: Not an Admin");
        _;
    }

    /**
     * @notice Setup admin role
     * @param admin Address that will have the admin role
     */
    function _setUpAdmin(address admin) internal{
        // Grant the SLINGSHOT_ADMIN_ROLE to the address
        _grantRole(SLINGSHOT_ADMIN_ROLE,admin);

        /** 
         * 
         * In OpenZeppelin’s AccessControl, every role has an admin role, which is responsible for managing (granting/revoking)
         * that role:
                By default, every role is administered by DEFAULT_ADMIN_ROLE.
                That means only addresses with DEFAULT_ADMIN_ROLE can grantRole() or revokeRole() for any other role.
                If you want to delegate the ability to manage a specific role to another role (including to itself), 
                you need to set the admin role of that role manually.
         * 
         * 
         * For this case: bytes32 public constant SLINGSHOT_ADMIN_ROLE = keccak256(SLINGSHOT_ADMIN_ROLE);
         *      Without explicitly setting its admin, SLINGSHOT_ADMIN_ROLE will be administered by DEFAULT_ADMIN_ROLE. 
         *         That means:
         *              Only DEFAULT_ADMIN_ROLE holders can add/remove SLINGSHOT_ADMIN_ROLE members.
         *              SLINGSHOT_ADMIN_ROLE holders cannot manage their own group (i.e., they can’t add other admins).
         * 
         * Now, if you write:
         *  _setRoleAdminInternal(SLINGSHOT_ADMIN_ROLE, SLING_ADMIN_ROLE)
         * 
         * "I want the SLINGSHOT_ADMIN_ROLE to be self-managed. Members of this role can grant or revoke this
         *  same role to/from others
         */
        _setRoleAdminInternal(SLINGSHOT_ADMIN_ROLE, SLINGSHOT_ADMIN_ROLE);
    }

    /// @dev OpenZeppelin no longer exposes _setRoleAdmin, so we emulate the same logic here
    function _setRoleAdminInternal(bytes32 role, bytes32 adminRole) internal {
        // NOTE: OpenZeppelin removed _setRoleAdmin to prevent unsafe reconfiguration;
        // you should use role hierarchies cautiously.
        _roleAdmins[role] = adminRole;
    }

    /// @dev Override default getRoleAdmin to support our internal mapping
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        bytes32 customAdmin = _roleAdmins[role];
        if (customAdmin != bytes32(0)) {
            return customAdmin;
        }
        return super.getRoleAdmin(role);
    }


}

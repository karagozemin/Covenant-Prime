// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CovenantTypes} from "./CovenantTypes.sol";
import {CovenantVault} from "./CovenantVault.sol";

contract AuditorDisclosureModule {
    CovenantVault public immutable vault;
    mapping(uint256 covenantId => mapping(address auditor => bool)) public grantedAuditors;
    mapping(uint256 covenantId => bytes32[]) private auditTrail;

    event DisclosureRequested(uint256 indexed covenantId, address indexed auditor);
    event AuditorGranted(uint256 indexed covenantId, address indexed auditor);
    event AuditorRevoked(uint256 indexed covenantId, address indexed auditor);

    error Unauthorized();

    constructor(CovenantVault vault_) {
        vault = vault_;
    }

    function requestDisclosure(uint256 covenantId) external {
        CovenantTypes.CovenantConfig memory config = vault.getCovenant(covenantId);
        if (!config.allowDisclosure && !grantedAuditors[covenantId][msg.sender]) revert Unauthorized();
        emit DisclosureRequested(covenantId, msg.sender);
    }

    function grantAuditor(uint256 covenantId, address auditor) external {
        _requireOwner(covenantId);
        grantedAuditors[covenantId][auditor] = true;
        emit AuditorGranted(covenantId, auditor);
    }

    function revokeAuditor(uint256 covenantId, address auditor) external {
        _requireOwner(covenantId);
        grantedAuditors[covenantId][auditor] = false;
        emit AuditorRevoked(covenantId, auditor);
    }

    function recordAuditItem(uint256 covenantId, bytes32 item) external {
        _requireOwner(covenantId);
        auditTrail[covenantId].push(item);
    }

    function getAuditTrail(uint256 covenantId) external view returns (bytes32[] memory) {
        CovenantTypes.CovenantConfig memory config = vault.getCovenant(covenantId);
        if (msg.sender != config.owner && !config.allowDisclosure && !grantedAuditors[covenantId][msg.sender]) {
            revert Unauthorized();
        }
        return auditTrail[covenantId];
    }

    function _requireOwner(uint256 covenantId) private view {
        CovenantTypes.CovenantConfig memory config = vault.getCovenant(covenantId);
        if (config.owner != msg.sender) revert Unauthorized();
    }
}

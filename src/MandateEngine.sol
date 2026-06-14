// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CovenantTypes} from "./CovenantTypes.sol";
import {CovenantVault} from "./CovenantVault.sol";

contract MandateEngine {
    CovenantVault public immutable vault;

    constructor(CovenantVault vault_) {
        vault = vault_;
    }

    function validate(CovenantTypes.ActionRequest calldata request, address proposer)
        external
        view
        returns (bool allowed, CovenantTypes.ReasonCode reason)
    {
        CovenantTypes.CovenantConfig memory config = vault.getCovenant(request.covenantId);

        if (config.owner == address(0)) return (false, CovenantTypes.ReasonCode.COVENANT_NOT_FOUND);
        if (vault.revoked(request.covenantId)) return (false, CovenantTypes.ReasonCode.REVOKED_COVENANT);
        if (block.timestamp > config.expiry) return (false, CovenantTypes.ReasonCode.EXPIRED_COVENANT);
        if (proposer != request.agent || !vault.assignedAgents(request.covenantId, request.agent)) {
            return (false, CovenantTypes.ReasonCode.UNAUTHORIZED_AGENT);
        }
        if (!vault.allowedAssets(request.covenantId, request.asset)) {
            return (false, CovenantTypes.ReasonCode.DISALLOWED_ASSET);
        }
        if (!vault.allowedTargets(request.covenantId, request.target)) {
            return (false, CovenantTypes.ReasonCode.DISALLOWED_TARGET);
        }
        if (request.amount > config.maxSingleActionAmount) {
            return (false, CovenantTypes.ReasonCode.EXCEEDS_SINGLE_ACTION_LIMIT);
        }
        if (vault.totalSpent(request.covenantId) + request.amount > config.maxTotalSpend) {
            return (false, CovenantTypes.ReasonCode.EXCEEDS_TOTAL_SPEND);
        }
        if (vault.dailySpent(request.covenantId, block.timestamp / 1 days) + request.amount > config.dailyVolumeLimit) {
            return (false, CovenantTypes.ReasonCode.EXCEEDS_DAILY_VOLUME);
        }
        if (request.slippageBps > config.maxSlippageBps) return (false, CovenantTypes.ReasonCode.SLIPPAGE_TOO_HIGH);
        if (!vault.allowedRecipients(request.covenantId, request.recipient)) {
            return (false, CovenantTypes.ReasonCode.UNAUTHORIZED_RECIPIENT);
        }
        if (request.usesLeverage && !config.leverageAllowed) {
            return (false, CovenantTypes.ReasonCode.LEVERAGE_NOT_ALLOWED);
        }
        if (_isCorporateAction(request.actionType) && !config.allowCorporateActions) {
            return (false, CovenantTypes.ReasonCode.CORPORATE_ACTION_NOT_ALLOWED);
        }
        if (request.actionType == CovenantTypes.ActionType.DISCLOSE && !config.allowDisclosure) {
            return (false, CovenantTypes.ReasonCode.DISCLOSURE_NOT_ALLOWED);
        }

        return (true, CovenantTypes.ReasonCode.ALLOWED);
    }

    function _isCorporateAction(CovenantTypes.ActionType actionType) private pure returns (bool) {
        return actionType == CovenantTypes.ActionType.VOTE || actionType == CovenantTypes.ActionType.CLAIM;
    }
}

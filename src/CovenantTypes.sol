// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library CovenantTypes {
    enum ActionType {
        BUY,
        SELL,
        TRANSFER,
        VOTE,
        DISCLOSE,
        REPAY,
        CLAIM,
        REBALANCE
    }

    enum ReasonCode {
        ALLOWED,
        COVENANT_NOT_FOUND,
        REVOKED_COVENANT,
        EXPIRED_COVENANT,
        UNAUTHORIZED_AGENT,
        DISALLOWED_ASSET,
        DISALLOWED_TARGET,
        EXCEEDS_SINGLE_ACTION_LIMIT,
        EXCEEDS_TOTAL_SPEND,
        EXCEEDS_DAILY_VOLUME,
        SLIPPAGE_TOO_HIGH,
        UNAUTHORIZED_RECIPIENT,
        LEVERAGE_NOT_ALLOWED,
        CORPORATE_ACTION_NOT_ALLOWED,
        DISCLOSURE_NOT_ALLOWED
    }

    struct CovenantConfig {
        address owner;
        address agent;
        uint256 maxTotalSpend;
        uint256 maxSingleActionAmount;
        uint256 dailyVolumeLimit;
        uint64 expiry;
        address[] allowedAssets;
        address[] allowedTargets;
        address[] allowedRecipients;
        bool allowCorporateActions;
        bool allowDisclosure;
        uint16 maxSlippageBps;
        bool leverageAllowed;
    }

    struct ActionRequest {
        uint256 covenantId;
        address agent;
        ActionType actionType;
        address asset;
        address target;
        uint256 amount;
        address recipient;
        uint16 slippageBps;
        bool usesLeverage;
        bytes32 metadataHash;
    }
}

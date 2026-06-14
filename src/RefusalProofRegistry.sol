// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CovenantTypes} from "./CovenantTypes.sol";

contract RefusalProofRegistry {
    struct RefusalProof {
        uint256 proofId;
        uint256 covenantId;
        address agent;
        bytes32 actionHash;
        CovenantTypes.ReasonCode reasonCode;
        uint64 timestamp;
        address asset;
        uint256 amount;
        address target;
        bytes32 metadataHash;
    }

    address public immutable admin;
    address public router;
    uint256 public nextProofId = 1;
    mapping(uint256 id => RefusalProof proof) private proofs;
    mapping(uint256 covenantId => uint256[] proofIds) private covenantProofs;
    mapping(address agent => uint256[] proofIds) private agentProofs;

    event RefusalProofRecorded(
        uint256 indexed proofId,
        uint256 indexed covenantId,
        address indexed agent,
        CovenantTypes.ReasonCode reasonCode,
        bytes32 actionHash
    );

    error Unauthorized();

    constructor() {
        admin = msg.sender;
    }

    function setRouter(address newRouter) external {
        if (msg.sender != admin) revert Unauthorized();
        router = newRouter;
    }

    function recordRefusal(
        CovenantTypes.ActionRequest calldata request,
        CovenantTypes.ReasonCode reasonCode,
        bytes32 actionHash
    ) external returns (uint256 proofId) {
        if (msg.sender != router) revert Unauthorized();
        proofId = nextProofId++;
        proofs[proofId] = RefusalProof({
            proofId: proofId,
            covenantId: request.covenantId,
            agent: request.agent,
            actionHash: actionHash,
            reasonCode: reasonCode,
            timestamp: uint64(block.timestamp),
            asset: request.asset,
            amount: request.amount,
            target: request.target,
            metadataHash: request.metadataHash
        });
        covenantProofs[request.covenantId].push(proofId);
        agentProofs[request.agent].push(proofId);
        emit RefusalProofRecorded(proofId, request.covenantId, request.agent, reasonCode, actionHash);
    }

    function getProof(uint256 proofId) external view returns (RefusalProof memory) {
        return proofs[proofId];
    }

    function getProofsByCovenant(uint256 covenantId) external view returns (uint256[] memory) {
        return covenantProofs[covenantId];
    }

    function getProofsByAgent(address agent) external view returns (uint256[] memory) {
        return agentProofs[agent];
    }
}

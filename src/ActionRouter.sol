// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CovenantTypes} from "./CovenantTypes.sol";
import {CovenantVault} from "./CovenantVault.sol";
import {MandateEngine} from "./MandateEngine.sol";
import {RefusalProofRegistry} from "./RefusalProofRegistry.sol";
import {MockExchange} from "./MockExchange.sol";

interface IActionTarget {
    function executeAction(
        uint256 covenantId,
        uint8 actionType,
        address asset,
        uint256 amount,
        address recipient,
        bytes32 metadataHash
    ) external;
}

contract ActionRouter {
    struct ExecutionReceipt {
        uint256 receiptId;
        uint256 covenantId;
        bytes32 actionHash;
        address agent;
        CovenantTypes.ActionType actionType;
        uint256 amount;
        uint64 timestamp;
    }

    CovenantVault public immutable vault;
    MandateEngine public immutable engine;
    RefusalProofRegistry public immutable registry;
    address public immutable admin;
    bool public paused;
    uint256 public nextReceiptId = 1;
    mapping(uint256 id => ExecutionReceipt receipt) public receipts;
    mapping(uint256 covenantId => uint256[] receiptIds) private covenantReceipts;
    mapping(address agent => uint256[] receiptIds) private agentReceipts;

    event ActionApproved(uint256 indexed covenantId, bytes32 indexed actionHash, address indexed agent);
    event ActionExecuted(uint256 indexed receiptId, uint256 indexed covenantId, bytes32 indexed actionHash);
    event ActionRefused(uint256 indexed covenantId, bytes32 indexed actionHash, CovenantTypes.ReasonCode reasonCode);
    event PauseSet(bool paused);

    error Unauthorized();
    error Paused();
    error ReentrantCall();

    constructor(CovenantVault vault_, MandateEngine engine_, RefusalProofRegistry registry_) {
        vault = vault_;
        engine = engine_;
        registry = registry_;
        admin = msg.sender;
    }

    uint256 private locked = 1;

    function setPaused(bool paused_) external {
        if (msg.sender != admin) revert Unauthorized();
        paused = paused_;
        emit PauseSet(paused_);
    }

    function proposeAction(CovenantTypes.ActionRequest calldata request)
        external
        whenNotPaused
        nonReentrant
        returns (bool allowed, CovenantTypes.ReasonCode reason, uint256 recordId)
    {
        return _executeIfAllowed(request);
    }

    function executeIfAllowed(CovenantTypes.ActionRequest calldata request)
        external
        whenNotPaused
        nonReentrant
        returns (bool allowed, CovenantTypes.ReasonCode reason, uint256 recordId)
    {
        return _executeIfAllowed(request);
    }

    function simulateAction(CovenantTypes.ActionRequest calldata request)
        external
        view
        returns (bool allowed, CovenantTypes.ReasonCode reason)
    {
        return engine.validate(request, msg.sender);
    }

    function _executeIfAllowed(CovenantTypes.ActionRequest calldata request)
        private
        returns (bool allowed, CovenantTypes.ReasonCode reason, uint256 recordId)
    {
        bytes32 actionHash = keccak256(abi.encode(request));
        (allowed, reason) = engine.validate(request, msg.sender);

        if (!allowed) {
            recordId = registry.recordRefusal(request, reason, actionHash, msg.sender);
            emit ActionRefused(request.covenantId, actionHash, reason);
            return (false, reason, recordId);
        }

        emit ActionApproved(request.covenantId, actionHash, request.agent);
        vault.recordSpend(request.covenantId, request.amount);
        _route(request);

        recordId = nextReceiptId++;
        receipts[recordId] = ExecutionReceipt({
            receiptId: recordId,
            covenantId: request.covenantId,
            actionHash: actionHash,
            agent: request.agent,
            actionType: request.actionType,
            amount: request.amount,
            timestamp: uint64(block.timestamp)
        });
        covenantReceipts[request.covenantId].push(recordId);
        agentReceipts[msg.sender].push(recordId);
        emit ActionExecuted(recordId, request.covenantId, actionHash);
    }

    function getReceiptsByCovenant(uint256 covenantId) external view returns (uint256[] memory) {
        return covenantReceipts[covenantId];
    }

    function getReceiptsByAgent(address agent) external view returns (uint256[] memory) {
        return agentReceipts[agent];
    }

    function _route(CovenantTypes.ActionRequest calldata request) private {
        if (request.actionType == CovenantTypes.ActionType.BUY) {
            MockExchange(request.target).buy(request.asset, request.amount, request.recipient);
        } else if (request.actionType == CovenantTypes.ActionType.SELL) {
            MockExchange(request.target).sell(request.asset, request.amount, request.recipient);
        } else {
            IActionTarget(request.target).executeAction(
                request.covenantId,
                uint8(request.actionType),
                request.asset,
                request.amount,
                request.recipient,
                request.metadataHash
            );
        }
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier nonReentrant() {
        if (locked != 1) revert ReentrantCall();
        locked = 2;
        _;
        locked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CovenantTypes} from "./CovenantTypes.sol";
import {CovenantVault} from "./CovenantVault.sol";
import {MandateEngine} from "./MandateEngine.sol";
import {RefusalProofRegistry} from "./RefusalProofRegistry.sol";
import {MockExchange} from "./MockExchange.sol";

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
    uint256 public nextReceiptId = 1;
    mapping(uint256 id => ExecutionReceipt receipt) public receipts;

    event ActionApproved(uint256 indexed covenantId, bytes32 indexed actionHash, address indexed agent);
    event ActionExecuted(uint256 indexed receiptId, uint256 indexed covenantId, bytes32 indexed actionHash);
    event ActionRefused(uint256 indexed covenantId, bytes32 indexed actionHash, CovenantTypes.ReasonCode reasonCode);

    constructor(CovenantVault vault_, MandateEngine engine_, RefusalProofRegistry registry_) {
        vault = vault_;
        engine = engine_;
        registry = registry_;
    }

    function proposeAction(CovenantTypes.ActionRequest calldata request)
        external
        returns (bool allowed, CovenantTypes.ReasonCode reason, uint256 recordId)
    {
        return _executeIfAllowed(request);
    }

    function executeIfAllowed(CovenantTypes.ActionRequest calldata request)
        external
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
            recordId = registry.recordRefusal(request, reason, actionHash);
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
        emit ActionExecuted(recordId, request.covenantId, actionHash);
    }

    function _route(CovenantTypes.ActionRequest calldata request) private {
        if (request.actionType == CovenantTypes.ActionType.BUY) {
            MockExchange(request.target).buy(request.asset, request.amount, request.recipient);
        } else if (request.actionType == CovenantTypes.ActionType.SELL) {
            MockExchange(request.target).sell(request.asset, request.amount, request.recipient);
        } else {
            (bool success,) = request.target.call(
                abi.encodeWithSignature(
                    "executeAction(uint8,address,uint256,address,bytes32)",
                    uint8(request.actionType),
                    request.asset,
                    request.amount,
                    request.recipient,
                    request.metadataHash
                )
            );
            require(success, "LIFECYCLE_EXECUTION_FAILED");
        }
    }
}

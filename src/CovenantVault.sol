// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CovenantTypes} from "./CovenantTypes.sol";
import {IERC20} from "./interfaces/IERC20.sol";

contract CovenantVault {
    using CovenantTypes for CovenantTypes.CovenantConfig;

    address public immutable admin;
    address public router;
    uint256 public nextCovenantId = 1;

    mapping(address user => mapping(address token => uint256 amount)) public balances;
    mapping(uint256 id => CovenantTypes.CovenantConfig config) private covenants;
    mapping(uint256 id => bool) public revoked;
    mapping(uint256 id => mapping(address agent => bool)) public assignedAgents;
    mapping(uint256 id => mapping(address asset => bool)) public allowedAssets;
    mapping(uint256 id => mapping(address target => bool)) public allowedTargets;
    mapping(uint256 id => mapping(address recipient => bool)) public allowedRecipients;
    mapping(uint256 id => uint256 amount) public totalSpent;
    mapping(uint256 id => mapping(uint256 day => uint256 amount)) public dailySpent;

    event Deposited(address indexed user, address indexed token, uint256 amount);
    event Withdrawn(address indexed user, address indexed token, uint256 amount);
    event CovenantCreated(uint256 indexed covenantId, address indexed user, address indexed agent);
    event CovenantRevoked(uint256 indexed covenantId);
    event AgentAssigned(uint256 indexed covenantId, address indexed agent);
    event AgentRevoked(uint256 indexed covenantId, address indexed agent);
    event RouterSet(address indexed router);

    error Unauthorized();
    error InvalidConfig();
    error InsufficientBalance();
    error TransferFailed();

    constructor() {
        admin = msg.sender;
    }

    function setRouter(address newRouter) external {
        if (msg.sender != admin) revert Unauthorized();
        router = newRouter;
        emit RouterSet(newRouter);
    }

    function deposit(address token, uint256 amount) external {
        if (!IERC20(token).transferFrom(msg.sender, address(this), amount)) revert TransferFailed();
        balances[msg.sender][token] += amount;
        emit Deposited(msg.sender, token, amount);
    }

    function withdraw(address token, uint256 amount) external {
        if (balances[msg.sender][token] < amount) revert InsufficientBalance();
        balances[msg.sender][token] -= amount;
        if (!IERC20(token).transfer(msg.sender, amount)) revert TransferFailed();
        emit Withdrawn(msg.sender, token, amount);
    }

    function createCovenant(CovenantTypes.CovenantConfig calldata config) external returns (uint256 covenantId) {
        if (config.owner != msg.sender || config.expiry <= block.timestamp || config.agent == address(0)) {
            revert InvalidConfig();
        }

        covenantId = nextCovenantId++;
        CovenantTypes.CovenantConfig storage saved = covenants[covenantId];
        saved.owner = config.owner;
        saved.agent = config.agent;
        saved.maxTotalSpend = config.maxTotalSpend;
        saved.maxSingleActionAmount = config.maxSingleActionAmount;
        saved.dailyVolumeLimit = config.dailyVolumeLimit;
        saved.expiry = config.expiry;
        saved.allowCorporateActions = config.allowCorporateActions;
        saved.allowDisclosure = config.allowDisclosure;
        saved.maxSlippageBps = config.maxSlippageBps;
        saved.leverageAllowed = config.leverageAllowed;

        for (uint256 i; i < config.allowedAssets.length; i++) {
            saved.allowedAssets.push(config.allowedAssets[i]);
            allowedAssets[covenantId][config.allowedAssets[i]] = true;
        }
        for (uint256 i; i < config.allowedTargets.length; i++) {
            saved.allowedTargets.push(config.allowedTargets[i]);
            allowedTargets[covenantId][config.allowedTargets[i]] = true;
        }
        for (uint256 i; i < config.allowedRecipients.length; i++) {
            saved.allowedRecipients.push(config.allowedRecipients[i]);
            allowedRecipients[covenantId][config.allowedRecipients[i]] = true;
        }

        assignedAgents[covenantId][config.agent] = true;
        emit CovenantCreated(covenantId, msg.sender, config.agent);
    }

    function revokeCovenant(uint256 covenantId) external onlyCovenantOwner(covenantId) {
        revoked[covenantId] = true;
        emit CovenantRevoked(covenantId);
    }

    function assignAgent(uint256 covenantId, address agent) external onlyCovenantOwner(covenantId) {
        assignedAgents[covenantId][agent] = true;
        emit AgentAssigned(covenantId, agent);
    }

    function revokeAgent(uint256 covenantId, address agent) external onlyCovenantOwner(covenantId) {
        assignedAgents[covenantId][agent] = false;
        emit AgentRevoked(covenantId, agent);
    }

    function recordSpend(uint256 covenantId, uint256 amount) external {
        if (msg.sender != router) revert Unauthorized();
        totalSpent[covenantId] += amount;
        dailySpent[covenantId][block.timestamp / 1 days] += amount;
    }

    function getCovenant(uint256 covenantId) external view returns (CovenantTypes.CovenantConfig memory) {
        return covenants[covenantId];
    }

    modifier onlyCovenantOwner(uint256 covenantId) {
        if (covenants[covenantId].owner != msg.sender) revert Unauthorized();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CovenantTypes} from "./CovenantTypes.sol";
import {IERC20} from "./interfaces/IERC20.sol";

contract CovenantVault {
    using CovenantTypes for CovenantTypes.CovenantConfig;

    address public immutable admin;
    address public router;
    bool public paused;
    uint256 public nextCovenantId = 1;

    mapping(address user => mapping(address token => uint256 amount)) public balances;
    mapping(address owner => uint256[] covenantIds) private ownerCovenants;
    mapping(address agent => uint256[] covenantIds) private agentCovenants;
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
    event PauseSet(bool paused);

    error Unauthorized();
    error InvalidConfig();
    error InsufficientBalance();
    error TransferFailed();
    error Paused();
    error ReentrantCall();

    uint256 private locked = 1;

    constructor() {
        admin = msg.sender;
    }

    function setRouter(address newRouter) external {
        if (msg.sender != admin) revert Unauthorized();
        if (newRouter == address(0)) revert InvalidConfig();
        router = newRouter;
        emit RouterSet(newRouter);
    }

    function setPaused(bool paused_) external {
        if (msg.sender != admin) revert Unauthorized();
        paused = paused_;
        emit PauseSet(paused_);
    }

    function deposit(address token, uint256 amount) external whenNotPaused nonReentrant {
        if (token == address(0) || amount == 0) revert InvalidConfig();
        if (!IERC20(token).transferFrom(msg.sender, address(this), amount)) revert TransferFailed();
        balances[msg.sender][token] += amount;
        emit Deposited(msg.sender, token, amount);
    }

    function withdraw(address token, uint256 amount) external whenNotPaused nonReentrant {
        if (token == address(0) || amount == 0) revert InvalidConfig();
        if (balances[msg.sender][token] < amount) revert InsufficientBalance();
        balances[msg.sender][token] -= amount;
        if (!IERC20(token).transfer(msg.sender, amount)) revert TransferFailed();
        emit Withdrawn(msg.sender, token, amount);
    }

    function createCovenant(CovenantTypes.CovenantConfig calldata config)
        external
        whenNotPaused
        returns (uint256 covenantId)
    {
        if (
            config.owner != msg.sender || config.expiry <= block.timestamp || config.agent == address(0)
                || config.maxTotalSpend == 0 || config.maxSingleActionAmount == 0 || config.dailyVolumeLimit == 0
                || config.maxSingleActionAmount > config.maxTotalSpend || config.maxSlippageBps > 10_000
                || config.allowedAssets.length == 0 || config.allowedTargets.length == 0
                || config.allowedRecipients.length == 0
        ) {
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
        ownerCovenants[config.owner].push(covenantId);
        agentCovenants[config.agent].push(covenantId);
        emit CovenantCreated(covenantId, msg.sender, config.agent);
    }

    function revokeCovenant(uint256 covenantId) external whenNotPaused onlyCovenantOwner(covenantId) {
        revoked[covenantId] = true;
        emit CovenantRevoked(covenantId);
    }

    function assignAgent(uint256 covenantId, address agent) external whenNotPaused onlyCovenantOwner(covenantId) {
        if (agent == address(0)) revert InvalidConfig();
        if (!assignedAgents[covenantId][agent]) agentCovenants[agent].push(covenantId);
        assignedAgents[covenantId][agent] = true;
        emit AgentAssigned(covenantId, agent);
    }

    function revokeAgent(uint256 covenantId, address agent) external whenNotPaused onlyCovenantOwner(covenantId) {
        assignedAgents[covenantId][agent] = false;
        emit AgentRevoked(covenantId, agent);
    }

    function recordSpend(uint256 covenantId, uint256 amount) external whenNotPaused {
        if (msg.sender != router) revert Unauthorized();
        if (covenants[covenantId].owner == address(0) || revoked[covenantId]) revert InvalidConfig();
        totalSpent[covenantId] += amount;
        dailySpent[covenantId][block.timestamp / 1 days] += amount;
    }

    function getCovenant(uint256 covenantId) external view returns (CovenantTypes.CovenantConfig memory) {
        return covenants[covenantId];
    }

    function getCovenantsByOwner(address owner) external view returns (uint256[] memory) {
        return ownerCovenants[owner];
    }

    function getCovenantsByAgent(address agent) external view returns (uint256[] memory) {
        return agentCovenants[agent];
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

    modifier onlyCovenantOwner(uint256 covenantId) {
        if (covenants[covenantId].owner != msg.sender) revert Unauthorized();
        _;
    }
}

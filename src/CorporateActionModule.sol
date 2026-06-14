// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract CorporateActionModule {
    struct Vote {
        address asset;
        bytes32 proposalHash;
        bool active;
    }

    mapping(uint256 voteId => Vote vote) public votes;
    mapping(address asset => uint256 amount) public dividends;
    address public immutable admin;
    address public router;
    uint256 public nextVoteId = 1;

    event VoteCreated(uint256 indexed voteId, address indexed asset, bytes32 proposalHash);
    event AgentVoted(uint256 indexed covenantId, uint256 indexed voteId, uint8 choice);
    event DividendCreated(address indexed asset, uint256 amount);
    event DividendClaimed(uint256 indexed covenantId, address indexed asset, uint256 amount);
    event RouterSet(address indexed router);

    error Unauthorized();
    error InvalidConfig();
    error UnsupportedAction();

    constructor() {
        admin = msg.sender;
    }

    function setRouter(address router_) external {
        if (msg.sender != admin) revert Unauthorized();
        if (router_ == address(0)) revert InvalidConfig();
        router = router_;
        emit RouterSet(router_);
    }

    function createVote(address asset, bytes32 proposalHash) external returns (uint256 voteId) {
        if (msg.sender != admin) revert Unauthorized();
        voteId = nextVoteId++;
        votes[voteId] = Vote(asset, proposalHash, true);
        emit VoteCreated(voteId, asset, proposalHash);
    }

    function createDividend(address asset, uint256 amount) external {
        if (msg.sender != admin) revert Unauthorized();
        dividends[asset] += amount;
        emit DividendCreated(asset, amount);
    }

    function executeAction(
        uint256 covenantId,
        uint8 actionType,
        address asset,
        uint256 amount,
        address,
        bytes32 metadataHash
    ) external {
        if (msg.sender != router) revert Unauthorized();
        if (actionType == 3) {
            emit AgentVoted(covenantId, uint256(metadataHash), uint8(amount));
        } else if (actionType == 6) {
            dividends[asset] -= amount;
            emit DividendClaimed(covenantId, asset, amount);
        } else {
            revert UnsupportedAction();
        }
    }
}

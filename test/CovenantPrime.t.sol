// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {CovenantTypes} from "../src/CovenantTypes.sol";
import {CovenantVault} from "../src/CovenantVault.sol";
import {MandateEngine} from "../src/MandateEngine.sol";
import {RefusalProofRegistry} from "../src/RefusalProofRegistry.sol";
import {ActionRouter} from "../src/ActionRouter.sol";
import {MockExchange} from "../src/MockExchange.sol";
import {MockTokenizedStock} from "../src/MockTokenizedStock.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {CorporateActionModule} from "../src/CorporateActionModule.sol";
import {AuditorDisclosureModule} from "../src/AuditorDisclosureModule.sol";

contract CovenantPrimeTest is Test {
    CovenantVault vault;
    MandateEngine engine;
    RefusalProofRegistry registry;
    ActionRouter router;
    MockExchange exchange;
    MockTokenizedStock mNVDA;
    MockTokenizedStock randomAsset;
    MockUSDC usdc;
    CorporateActionModule corporateActions;
    AuditorDisclosureModule disclosure;

    address owner = makeAddr("owner");
    address agent = makeAddr("agent");
    address attacker = makeAddr("attacker");
    address auditor = makeAddr("auditor");
    uint256 covenantId;

    event ActionExecuted(uint256 indexed receiptId, uint256 indexed covenantId, bytes32 indexed actionHash);
    event AgentVoted(uint256 indexed covenantId, uint256 indexed voteId, uint8 choice);

    function setUp() public {
        vault = new CovenantVault();
        engine = new MandateEngine(vault);
        registry = new RefusalProofRegistry();
        router = new ActionRouter(vault, engine, registry);
        exchange = new MockExchange();
        mNVDA = new MockTokenizedStock("Mock NVIDIA", "mNVDA");
        randomAsset = new MockTokenizedStock("Random Asset", "RND");
        usdc = new MockUSDC();
        corporateActions = new CorporateActionModule();
        disclosure = new AuditorDisclosureModule(vault);
        vault.setRouter(address(router));
        registry.setRouter(address(router));
        corporateActions.setRouter(address(router));

        covenantId = _createCovenant(false, false, 1_000e6, 500e6, 700e6);
    }

    function testUserCanCreateCovenant() public view {
        CovenantTypes.CovenantConfig memory config = vault.getCovenant(covenantId);
        assertEq(config.owner, owner);
        assertEq(config.agent, agent);
        assertTrue(vault.assignedAgents(covenantId, agent));
        assertTrue(vault.allowedAssets(covenantId, address(mNVDA)));
        assertEq(vault.getCovenantsByOwner(owner)[0], covenantId);
        assertEq(vault.getCovenantsByAgent(agent)[0], covenantId);
    }

    function testDepositAndWithdraw() public {
        usdc.mint(owner, 1_000e6);
        vm.startPrank(owner);
        usdc.approve(address(vault), 1_000e6);
        vault.deposit(address(usdc), 1_000e6);
        vault.withdraw(address(usdc), 200e6);
        vm.stopPrank();
        assertEq(vault.balances(owner, address(usdc)), 800e6);
    }

    function testAssignedAgentCanExecuteAllowedAction() public {
        (bool allowed, CovenantTypes.ReasonCode reason, uint256 receiptId) = _propose(agent, _validBuy(200e6));
        assertTrue(allowed);
        assertEq(uint8(reason), uint8(CovenantTypes.ReasonCode.ALLOWED));
        assertEq(receiptId, 1);
        assertEq(vault.totalSpent(covenantId), 200e6);
        assertEq(mNVDA.balanceOf(owner), 200e18);
        assertEq(router.getReceiptsByCovenant(covenantId)[0], receiptId);
        assertEq(router.getReceiptsByAgent(agent)[0], receiptId);
    }

    function testUnauthorizedAgentIsRefused() public {
        CovenantTypes.ActionRequest memory request = _validBuy(200e6);
        (,, uint256 proofId) = _propose(attacker, request);
        assertEq(registry.getProof(proofId).agent, attacker);
    }

    function testDisallowedAssetIsRefused() public {
        CovenantTypes.ActionRequest memory request = _validBuy(200e6);
        request.asset = address(randomAsset);
        _assertRefused(agent, request, CovenantTypes.ReasonCode.DISALLOWED_ASSET);
    }

    function testExceedingMaxSingleActionIsRefused() public {
        _assertRefused(agent, _validBuy(501e6), CovenantTypes.ReasonCode.EXCEEDS_SINGLE_ACTION_LIMIT);
    }

    function testExceedingTotalSpendIsRefused() public {
        uint256 generousDaily = _createCovenant(false, false, 600e6, 500e6, 2_000e6);
        CovenantTypes.ActionRequest memory first = _validBuy(500e6);
        first.covenantId = generousDaily;
        _propose(agent, first);
        CovenantTypes.ActionRequest memory second = _validBuy(101e6);
        second.covenantId = generousDaily;
        _assertRefused(agent, second, CovenantTypes.ReasonCode.EXCEEDS_TOTAL_SPEND);
    }

    function testExceedingDailyVolumeIsRefused() public {
        _propose(agent, _validBuy(500e6));
        _assertRefused(agent, _validBuy(201e6), CovenantTypes.ReasonCode.EXCEEDS_DAILY_VOLUME);
    }

    function testExpiredCovenantIsRefused() public {
        vm.warp(block.timestamp + 8 days);
        _assertRefused(agent, _validBuy(200e6), CovenantTypes.ReasonCode.EXPIRED_COVENANT);
    }

    function testHighSlippageIsRefused() public {
        CovenantTypes.ActionRequest memory request = _validBuy(200e6);
        request.slippageBps = 800;
        _assertRefused(agent, request, CovenantTypes.ReasonCode.SLIPPAGE_TOO_HIGH);
    }

    function testUnauthorizedRecipientIsRefused() public {
        CovenantTypes.ActionRequest memory request = _validBuy(200e6);
        request.recipient = attacker;
        _assertRefused(agent, request, CovenantTypes.ReasonCode.UNAUTHORIZED_RECIPIENT);
    }

    function testLeverageIsRefused() public {
        CovenantTypes.ActionRequest memory request = _validBuy(200e6);
        request.usesLeverage = true;
        _assertRefused(agent, request, CovenantTypes.ReasonCode.LEVERAGE_NOT_ALLOWED);
    }

    function testForbiddenCorporateActionIsRefused() public {
        CovenantTypes.ActionRequest memory request = _validBuy(0);
        request.actionType = CovenantTypes.ActionType.VOTE;
        request.target = address(corporateActions);
        _assertRefused(agent, request, CovenantTypes.ReasonCode.CORPORATE_ACTION_NOT_ALLOWED);
    }

    function testForbiddenDisclosureIsRefused() public {
        CovenantTypes.ActionRequest memory request = _validBuy(0);
        request.actionType = CovenantTypes.ActionType.DISCLOSE;
        request.target = address(corporateActions);
        _assertRefused(agent, request, CovenantTypes.ReasonCode.DISCLOSURE_NOT_ALLOWED);
    }

    function testAllowedVoteCarriesCovenantId() public {
        uint256 voteCovenant = _createCovenant(true, false, 1_000e6, 500e6, 700e6);
        CovenantTypes.ActionRequest memory request = _validBuy(1);
        request.covenantId = voteCovenant;
        request.actionType = CovenantTypes.ActionType.VOTE;
        request.target = address(corporateActions);
        request.metadataHash = bytes32(uint256(14));
        vm.expectEmit(true, true, false, true);
        emit AgentVoted(voteCovenant, 14, 1);
        _propose(agent, request);
    }

    function testUnsupportedLifecycleActionCannotProduceFalseReceipt() public {
        CovenantTypes.ActionRequest memory request = _validBuy(1);
        request.actionType = CovenantTypes.ActionType.REBALANCE;
        request.target = address(corporateActions);
        vm.prank(agent);
        vm.expectRevert(CorporateActionModule.UnsupportedAction.selector);
        router.proposeAction(request);
        assertEq(router.nextReceiptId(), 1);
    }

    function testOnlyAdminCanCreateCorporateActions() public {
        vm.prank(attacker);
        vm.expectRevert(CorporateActionModule.Unauthorized.selector);
        corporateActions.createVote(address(mNVDA), bytes32(uint256(14)));
    }

    function testPauseBlocksCreationAndExecution() public {
        router.setPaused(true);
        vm.prank(agent);
        vm.expectRevert(ActionRouter.Paused.selector);
        router.proposeAction(_validBuy(200e6));

        vault.setPaused(true);
        vm.prank(owner);
        vm.expectRevert(CovenantVault.Paused.selector);
        vault.createCovenant(_config(false, false, 1_000e6, 500e6, 700e6));
    }

    function testInvalidConfigIsRejected() public {
        CovenantTypes.CovenantConfig memory config = _config(false, false, 500e6, 600e6, 700e6);
        vm.prank(owner);
        vm.expectRevert(CovenantVault.InvalidConfig.selector);
        vault.createCovenant(config);
    }

    function testRefusalProofIsRecordedCorrectly() public {
        CovenantTypes.ActionRequest memory request = _validBuy(900e6);
        (,, uint256 proofId) = _propose(agent, request);
        RefusalProofRegistry.RefusalProof memory proof = registry.getProof(proofId);
        assertEq(proof.covenantId, covenantId);
        assertEq(proof.agent, agent);
        assertEq(proof.amount, 900e6);
        assertEq(uint8(proof.reasonCode), uint8(CovenantTypes.ReasonCode.EXCEEDS_SINGLE_ACTION_LIMIT));
        assertEq(registry.getProofsByCovenant(covenantId).length, 1);
    }

    function testApprovedActionEmitsCorrectReceipt() public {
        CovenantTypes.ActionRequest memory request = _validBuy(200e6);
        bytes32 actionHash = keccak256(abi.encode(request));
        vm.expectEmit(true, true, true, true);
        emit ActionExecuted(1, covenantId, actionHash);
        _propose(agent, request);
        (uint256 receiptId, uint256 savedCovenantId, bytes32 savedHash,,,,) = router.receipts(1);
        assertEq(receiptId, 1);
        assertEq(savedCovenantId, covenantId);
        assertEq(savedHash, actionHash);
    }

    function testRevokedCovenantBlocksExecution() public {
        vm.prank(owner);
        vault.revokeCovenant(covenantId);
        _assertRefused(agent, _validBuy(200e6), CovenantTypes.ReasonCode.REVOKED_COVENANT);
    }

    function testAuditorCanViewOnlyPermittedDisclosure() public {
        vm.prank(auditor);
        vm.expectRevert(AuditorDisclosureModule.Unauthorized.selector);
        disclosure.getAuditTrail(covenantId);

        vm.prank(owner);
        disclosure.grantAuditor(covenantId, auditor);
        vm.prank(auditor);
        disclosure.getAuditTrail(covenantId);

        vm.prank(owner);
        disclosure.revokeAuditor(covenantId, auditor);
        vm.prank(auditor);
        vm.expectRevert(AuditorDisclosureModule.Unauthorized.selector);
        disclosure.getAuditTrail(covenantId);
    }

    function _createCovenant(
        bool allowCorporateActions,
        bool allowDisclosure,
        uint256 maxTotal,
        uint256 maxSingle,
        uint256 daily
    ) private returns (uint256 id) {
        CovenantTypes.CovenantConfig memory config =
            _config(allowCorporateActions, allowDisclosure, maxTotal, maxSingle, daily);
        vm.prank(owner);
        id = vault.createCovenant(config);
    }

    function _config(
        bool allowCorporateActions,
        bool allowDisclosure,
        uint256 maxTotal,
        uint256 maxSingle,
        uint256 daily
    ) private view returns (CovenantTypes.CovenantConfig memory config) {
        address[] memory assets = new address[](1);
        assets[0] = address(mNVDA);
        address[] memory targets = new address[](2);
        targets[0] = address(exchange);
        targets[1] = address(corporateActions);
        address[] memory recipients = new address[](1);
        recipients[0] = owner;

        config = CovenantTypes.CovenantConfig({
            owner: owner,
            agent: agent,
            maxTotalSpend: maxTotal,
            maxSingleActionAmount: maxSingle,
            dailyVolumeLimit: daily,
            expiry: uint64(block.timestamp + 7 days),
            allowedAssets: assets,
            allowedTargets: targets,
            allowedRecipients: recipients,
            allowCorporateActions: allowCorporateActions,
            allowDisclosure: allowDisclosure,
            maxSlippageBps: 100,
            leverageAllowed: false
        });
    }

    function _validBuy(uint256 amount) private view returns (CovenantTypes.ActionRequest memory) {
        return CovenantTypes.ActionRequest({
            covenantId: covenantId,
            agent: agent,
            actionType: CovenantTypes.ActionType.BUY,
            asset: address(mNVDA),
            target: address(exchange),
            amount: amount,
            recipient: owner,
            slippageBps: 50,
            usesLeverage: false,
            metadataHash: keccak256("AI_RISK_MEMO_001")
        });
    }

    function _propose(address proposer, CovenantTypes.ActionRequest memory request)
        private
        returns (bool allowed, CovenantTypes.ReasonCode reason, uint256 recordId)
    {
        vm.prank(proposer);
        return router.proposeAction(request);
    }

    function _assertRefused(
        address proposer,
        CovenantTypes.ActionRequest memory request,
        CovenantTypes.ReasonCode expected
    ) private {
        (bool allowed, CovenantTypes.ReasonCode reason, uint256 proofId) = _propose(proposer, request);
        assertFalse(allowed);
        assertEq(uint8(reason), uint8(expected));
        assertGt(proofId, 0);
    }
}

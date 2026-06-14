# Covenant Prime

## One-Liner

Covenant Prime is a proof-gated execution and lifecycle layer for AI-managed tokenized securities.

## Short Description

AI agents can manage tokenized securities, but every action must pass the covenant. Users define on-chain mandates for tokenized stock and RWA actions. Agents can trade, vote, repay, rebalance, or disclose only within those limits. Safe actions execute. Unsafe actions are rejected with verifiable refusal proofs.

## Long Description

Covenant Prime makes Robinhood Chain and Arbitrum safe for AI-managed tokenized securities. As AI agents begin managing tokenized stocks, private credit, and RWA portfolios, users need more than wallet permissions. They need enforceable boundaries.

Covenant Prime introduces on-chain covenants: programmable mandates that define exactly what an agent can and cannot do. Every proposed action is validated by the MandateEngine. If it is safe, ActionRouter executes it and emits an execution receipt. If it violates the covenant, RefusalProofRegistry records a verifiable refusal proof.

The result is a trust layer for agentic finance: agents can act, but they cannot betray the mandate.

## Judging Alignment

- **Smart contract quality:** Vault, mandate engine, action router, refusal proof registry, mock tokenized assets, corporate action module, and permissioned audit module.
- **Product-market fit:** Solves the core problem of safely delegating tokenized asset management to AI agents.
- **Innovation:** Combines agentic execution, tokenized security lifecycle controls, on-chain covenants, and refusal proofs.
- **Real problem solving:** Prevents unsafe AI financial actions before user funds are touched.
- **Robinhood Chain:** Standard EVM contracts and mock tokenized security lifecycle modules are ready for Robinhood Chain testnet deployment.
- **Arbitrum:** Primary deployment target and canonical refusal-proof registry.

## Demo Flow

1. Create a covenant for an AI agent.
2. Execute a safe tokenized stock action.
3. Attempt unsafe actions.
4. Show verifiable refusal proofs.
5. Show lifecycle actions.
6. Show the auditor dashboard.

## Technical Highlights

- Stable on-chain reason codes for precise refusals.
- Immutable refusal proofs indexed by covenant and agent.
- Separate read-only policy engine and state-changing execution router.
- Total and daily spend accounting enforced by the router.
- Full test suite with 18 passing Foundry tests.
- Polished judge-mode dashboard with deterministic action simulations.

## Key Phrase

**AI agents can manage tokenized securities, but every action must pass the covenant.**

## Closing Line

**This is not trust. This is enforceable finance.**

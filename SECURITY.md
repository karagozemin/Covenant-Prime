# Security

## Scope Notice

Covenant Prime is a hackathon proof of concept.

- Testnet only.
- No live funds.
- Mock tokenized stocks and a mock exchange.
- Not investment advice.
- Not a regulated broker, dealer, exchange, custodian, or transfer agent.
- Not audited and not suitable for production use.

## Implemented Controls

- Every agent proposal is checked by `MandateEngine`.
- Caller identity must match an assigned agent.
- Covenants can be revoked and expire automatically.
- Asset, target, and recipient allowlists are enforced.
- Single-action, total-spend, daily-volume, and slippage limits are enforced.
- Leverage, corporate action, and disclosure permissions are explicit.
- Only `ActionRouter` can update spend accounting.
- Only `ActionRouter` can write refusal proofs.
- Auditor access is owner-controlled when disclosure is not globally enabled.

## Known Limitations

- Approved target contracts are trusted once allowlisted.
- `ActionRouter` uses a generic lifecycle target call for non-trade actions.
- No reentrancy guard, pause system, multisig administration, or timelock.
- No oracle validation or market-price protection beyond supplied slippage data.
- No EIP-712 action signatures, nonce, replay protection, or relayer design.
- No fee accounting, position accounting, settlement finality, or cross-chain proof bridge.
- Mock ERC-20 assets are deliberately minimal.
- Contracts have not received formal verification or an external audit.

## Production Requirements

A production release would require:

1. Independent audits and formal verification of policy invariants.
2. Reentrancy protection, emergency pause, multisig, timelock, and carefully designed upgradeability.
3. EIP-712 signed intents with nonces, deadlines, replay protection, and session-key controls.
4. Trusted oracle integration and manipulation-resistant valuation.
5. Position-aware accounting and conservative settlement handling.
6. Target adapters with narrow interfaces instead of generic calls.
7. Regulatory, custody, identity, transfer-restriction, and jurisdiction review.
8. Operational monitoring, incident response, and key-management procedures.

Report security issues privately to the project maintainers. Do not use public testnets to demonstrate exploits against third-party deployments.

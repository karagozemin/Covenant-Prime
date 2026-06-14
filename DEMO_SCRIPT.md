# Covenant Prime Demo Script

## 30-Second Pitch

AI agents are about to manage real money, but today users either give them full wallet access or no access at all. Covenant Prime creates the missing layer: on-chain covenants for AI-managed tokenized securities. Users define what agents are allowed to do. Every trade, vote, repayment, rebalance, or disclosure is checked on-chain. Safe actions execute. Unsafe actions are rejected with verifiable refusal proofs.

## Six-Minute Flow

### 1. Frame The Problem

Open **Overview**.

“This is not an AI trading bot. Covenant Prime is the safety and execution layer between an AI agent and tokenized assets.”

Point to the live mandate engine, protected value, execution receipts, refusal proof count, and Arbitrum / Robinhood Chain compatibility.

### 2. Create The Mandate

Open **Create Covenant**.

Show the assigned agent, $500 single-action limit, allowed assets, 1% max slippage, corporate action toggle, blocked disclosure, and blocked leverage. Click **Create on-chain covenant**.

### 3. Execute A Safe Action

Open **Agent Console** and click **Valid buy**.

Explain that the mNVDA buy passes every check, updates spend accounting, executes through the approved target, and emits an execution receipt.

### 4. Prove Unsafe Actions Were Blocked

Run:

- Exceed cap
- Disallowed asset
- Unauthorized recipient
- High slippage
- Forbidden disclosure

Each proposal is refused before execution and receives a stable reason code.

### 5. Inspect A Refusal Proof

Open **Proof Dashboard** and select a proof.

Show the proof ID, covenant, agent, reason code, amount, action hash, and transaction hash.

“Most systems show successful transactions. Covenant Prime also proves that unsafe transactions never happened.”

### 6. Show The Larger Platform

Open **Lifecycle Mode** and **Auditor View**.

Explain that the same covenant governs trading, rebalancing, voting, dividends, repayments, disclosure, and audit access. The contracts are standard EVM and can deploy unchanged to Robinhood Chain testnet.

## Closing

**This is not trust. This is enforceable finance.**

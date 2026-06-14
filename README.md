<p align="center">
  <img src="./public/covenant-prime-mark.png" alt="Covenant Prime logo" width="180" />
</p>

<h1 align="center">Covenant Prime</h1>

<p align="center"><strong>AI-managed tokenized securities, enforced by on-chain covenants.</strong></p>

Covenant Prime is a proof-gated execution and lifecycle layer for AI-managed tokenized securities. A user defines an on-chain mandate, an agent proposes actions, and the protocol either executes the action or records a verifiable refusal proof explaining why it was blocked.

> AI agents can manage tokenized securities, but every action must pass the covenant.

## Why It Matters

Agent wallets are currently too binary: an agent gets broad signing authority or cannot act. Tokenized securities need a third option: bounded, transparent authority covering the full asset lifecycle. Covenant Prime enforces spend limits, asset and target allowlists, expiry, slippage, leverage, corporate action, recipient, and disclosure rules before execution.

Unsafe proposals do not disappear into an application log. `RefusalProofRegistry` preserves the action hash, covenant, agent, reason code, asset, amount, target, metadata hash, and timestamp on-chain.

## Demo

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000), then:

1. Create a covenant.
2. Run the valid mNVDA buy in Agent Console.
3. Run at least four attack scenarios.
4. Open Proof Dashboard and inspect a refusal proof.
5. Show Lifecycle Mode and Auditor View.

The frontend is an interactive deterministic demo surface. Contract calls are represented with realistic transaction hashes; deploy the contracts and connect these handlers for a live testnet demo.

## Contracts

| Contract | Purpose |
| --- | --- |
| `CovenantVault` | Custody accounting, covenant storage, agent assignment, and spend accounting |
| `MandateEngine` | Read-only validation of every proposed action |
| `ActionRouter` | Routes allowed actions and creates execution receipts |
| `RefusalProofRegistry` | Stores verifiable proofs for rejected actions |
| `MockExchange` | Simulates tokenized stock buy and sell execution |
| `MockTokenizedStock` | EVM-compatible mock mAAPL, mNVDA, and mTSLA assets |
| `CorporateActionModule` | Demonstrates voting and dividend lifecycle actions |
| `AuditorDisclosureModule` | Enforces permissioned audit-trail access |

## Architecture

```mermaid
flowchart LR
    U[User] -->|deposit + covenant| V[CovenantVault]
    A[AI Agent] -->|ActionRequest| R[ActionRouter]
    R -->|validate| M[MandateEngine]
    M -->|read policy + usage| V
    M -->|allowed| R
    R -->|execute| X[Exchange / Lifecycle Modules]
    R -->|receipt| E[Execution Receipt]
    M -->|refused + reason| R
    R -->|record| P[RefusalProofRegistry]
    P --> O[Auditor / Dashboard]
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for contract boundaries and action flow.

## Local Contract Setup

Requirements: Foundry, Node.js 20+, npm.

```bash
forge install
forge build
forge test -vv
```

Current test suite: **18 passing tests**, covering the required approved, refused, revoked, proof, receipt, vault, and auditor paths.

## Deploy To Arbitrum Sepolia

```bash
cp .env.example .env
source .env
forge script script/Deploy.s.sol:Deploy \
  --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast \
  --verify
```

### Deployment Addresses

No testnet deployment is committed to this repository. After deployment, record addresses here and in the frontend environment:

| Network | Contract | Address |
| --- | --- | --- |
| Arbitrum Sepolia | CovenantVault | `TBD` |
| Arbitrum Sepolia | MandateEngine | `TBD` |
| Arbitrum Sepolia | ActionRouter | `TBD` |
| Arbitrum Sepolia | RefusalProofRegistry | `TBD` |
| Arbitrum Sepolia | MockExchange | `TBD` |
| Arbitrum Sepolia | CorporateActionModule | `TBD` |

## Robinhood Chain Compatibility

All contracts are standard Solidity/EVM contracts with no Arbitrum-specific opcodes or system contract dependencies. The deployment script can target Robinhood Chain testnet by changing the RPC URL. `MockTokenizedStock` and `CorporateActionModule` demonstrate the tokenized security and lifecycle surface until native assets and issuer modules are available.

## Repository

```text
src/                 Solidity contracts
test/                Foundry policy and refusal tests
script/              Deployment script
app/                 Next.js demo dashboard
ARCHITECTURE.md       System design and trust boundaries
DEMO_SCRIPT.md        Judge-facing demo flow
SECURITY.md           Scope, limitations, and production requirements
SUBMISSION.md         Buildathon submission copy
```

## Limitations

- Testnet hackathon proof of concept; not audited.
- Mock exchange and mock tokenized stocks do not represent real securities.
- Frontend demo actions are deterministic simulations until wired to deployed addresses.
- No oracle, signature relay, upgrade process, or production custody controls.

## Roadmap

1. Deploy and verify the core suite on Arbitrum Sepolia and Robinhood Chain testnet.
2. Connect the dashboard to deployed contracts using viem.
3. Add EIP-712 signed agent intents and sponsored execution.
4. Integrate issuer lifecycle modules, oracle-priced limits, and institutional custody.
5. Add formal verification, independent audits, and production governance.

This is not trust. This is enforceable finance.

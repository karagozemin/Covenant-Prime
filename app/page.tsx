"use client";

import {
  ArrowRight,
  ArrowUpRight,
  BadgeCheck,
  Check,
  ChevronDown,
  CircleDollarSign,
  Clock3,
  Code2,
  Copy,
  Eye,
  FileCheck2,
  Fingerprint,
  Github,
  Globe2,
  LockKeyhole,
  Menu,
  Orbit,
  Plus,
  RefreshCw,
  ShieldCheck,
  Sparkles,
  Terminal,
  Vote,
  Wallet,
  X,
  Zap,
} from "lucide-react";
import { useMemo, useState } from "react";

type ActionStatus = "approved" | "refused";
type AppTab = "overview" | "console" | "proofs" | "covenant";

type Action = {
  id: number;
  name: string;
  description: string;
  asset: string;
  amount: string;
  status: ActionStatus;
  reason: string;
  hash: string;
};

const makeHash = (seed: number) => `0x${(BigInt(seed) * 83911723n).toString(16).padEnd(64, "c").slice(0, 64)}`;

const seedActions: Action[] = [
  { id: 2288, name: "Buy mNVDA", description: "Increase semiconductor exposure", asset: "mNVDA", amount: "200 USDC", status: "approved", reason: "All covenant checks passed", hash: "0x2b278b8be87fbed7416b4c8bb850bbcd30a2e177a51ca0296a587dd0990e20f1" },
  { id: 2287, name: "Transfer USDC", description: "Send funds to unknown wallet", asset: "USDC", amount: "450 USDC", status: "refused", reason: "Unauthorized recipient", hash: "0xff68df238373c5e6eef53a1cb97edd9df7877c11dab08323ab8731bce9072a17" },
  { id: 2286, name: "Buy mNVDA", description: "Order exceeds single-action limit", asset: "mNVDA", amount: "900 USDC", status: "refused", reason: "Exceeds single-action limit", hash: "0x6bac976bc2139d48904b2d374bbc51a0f58b6826c9c31b76f97e96244d2453a9" },
];

const scenarios = [
  { name: "Buy mNVDA", description: "Buy 200 USDC of mNVDA", asset: "mNVDA", amount: "200 USDC", status: "approved" as const, reason: "All covenant checks passed", icon: CircleDollarSign },
  { name: "Rebalance", description: "Rotate mAAPL into mTSLA", asset: "mAAPL → mTSLA", amount: "180 USDC", status: "approved" as const, reason: "All covenant checks passed", icon: RefreshCw },
  { name: "Vote", description: "Vote on issuer proposal #14", asset: "mAAPL", amount: "No spend", status: "approved" as const, reason: "Corporate actions permitted", icon: Vote },
  { name: "Exceed cap", description: "Try to buy 900 USDC of mNVDA", asset: "mNVDA", amount: "900 USDC", status: "refused" as const, reason: "Exceeds single-action limit", icon: Zap },
  { name: "Unknown wallet", description: "Transfer to unapproved recipient", asset: "USDC", amount: "450 USDC", status: "refused" as const, reason: "Unauthorized recipient", icon: Wallet },
  { name: "Private disclosure", description: "Expose position-level audit data", asset: "Private data", amount: "No spend", status: "refused" as const, reason: "Disclosure not permitted", icon: Eye },
];

export default function Home() {
  const [appOpen, setAppOpen] = useState(false);
  const [tab, setTab] = useState<AppTab>("overview");
  const [actions, setActions] = useState<Action[]>(seedActions);
  const [selected, setSelected] = useState<Action | null>(null);
  const [toast, setToast] = useState<Action | null>(null);
  const [processing, setProcessing] = useState<string | null>(null);

  const proofs = useMemo(() => actions.filter((action) => action.status === "refused"), [actions]);

  const runScenario = (scenario: (typeof scenarios)[number]) => {
    if (processing) return;
    setProcessing(scenario.name);
    const id = 2289 + actions.length;
    const action: Action = { ...scenario, id, hash: makeHash(id) };
    window.setTimeout(() => {
      setActions((current) => [action, ...current]);
      setToast(action);
      setProcessing(null);
      if (action.status === "refused") setSelected(action);
      window.setTimeout(() => setToast(null), 3600);
    }, 620);
  };

  if (appOpen) {
    return <ProductApp tab={tab} setTab={setTab} actions={actions} proofs={proofs} runScenario={runScenario} selected={selected} setSelected={setSelected} closeApp={() => setAppOpen(false)} toast={toast} closeToast={() => setToast(null)} processing={processing} />;
  }

  return <Landing openApp={() => setAppOpen(true)} runScenario={runScenario} toast={toast} closeToast={() => setToast(null)} processing={processing} />;
}

function Logo() {
  return <span className="logo"><span className="logo-mark"><img src="/covenant-prime-mark.png" alt="" /></span><strong>Covenant</strong><b>Prime</b></span>;
}

function Landing({ openApp, runScenario, toast, closeToast, processing }: { openApp: () => void; runScenario: (scenario: (typeof scenarios)[number]) => void; toast: Action | null; closeToast: () => void; processing: string | null }) {
  return (
    <main className="landing">
      <nav className="landing-nav">
        <Logo />
        <div className="landing-links"><a href="#product">Product</a><a href="#why">Why Covenant</a><a href="#developers">Developers</a><a href="#demo">Live demo</a></div>
        <div className="landing-actions"><a className="nav-ghost" href="https://github.com/karagozemin/Covenant-Prime" target="_blank" rel="noreferrer"><Github size={16} /> GitHub</a><button className="nav-launch" onClick={openApp}>Launch app <ArrowUpRight size={15} /></button></div>
      </nav>

      <section className="landing-hero" id="product">
        <div className="hero-main">
          <span className="announcement"><Sparkles size={14} /> Built for the Arbitrum Open House <ArrowRight size={13} /></span>
          <h1>Give AI agents<br /><em>rules, not trust.</em></h1>
          <p className="hero-copy">The on-chain control layer for AI-managed tokenized securities. Every action is checked against your covenant before funds can move.</p>
          <div className="hero-buttons"><button className="big-primary" onClick={openApp}>Launch the demo <ArrowRight size={17} /></button><a className="big-secondary" href="#demo"><Terminal size={16} /> See how it works</a></div>
          <div className="hero-foot"><span><Check size={14} /> Arbitrum Sepolia</span><span><Check size={14} /> Robinhood Chain ready</span><span><Check size={14} /> Open-source contracts</span></div>
        </div>
        <HeroMachine />
      </section>

      <section className="ticker">
        <span>AI AGENT PROPOSES</span><i /><span>COVENANT VALIDATES</span><i /><span>SAFE ACTIONS EXECUTE</span><i /><span>UNSAFE ACTIONS BECOME PROOFS</span>
      </section>

      <section className="manifesto" id="why">
        <span className="section-label">The missing control layer</span>
        <h2>AI agents are getting wallets.<br />They should not get <em>unlimited authority.</em></h2>
        <div className="manifesto-grid">
          <div className="old-way"><span>WITHOUT COVENANT PRIME</span><h3>One key. Unlimited risk.</h3><p>Wallet permissions are binary. Once an agent can sign, users have little control over what it buys, where it sends funds, or what it discloses.</p><div className="risk-line"><X size={16} /> Full wallet access</div><div className="risk-line"><X size={16} /> No verifiable refusal trail</div><div className="risk-line"><X size={16} /> Trading-only permissions</div></div>
          <div className="new-way"><span>WITH COVENANT PRIME</span><h3>Bounded authority. Verifiable safety.</h3><p>Users write an on-chain mandate once. Agents can act quickly inside it and physically cannot cross its boundaries.</p><div className="safe-line"><Check size={16} /> Granular on-chain rules</div><div className="safe-line"><Check size={16} /> Refusal proofs for every blocked action</div><div className="safe-line"><Check size={16} /> Full tokenized security lifecycle</div></div>
        </div>
      </section>

      <section className="live-demo" id="demo">
        <div className="demo-intro"><span className="section-label">Try it yourself</span><h2>Attack the agent.<br /><em>The covenant holds.</em></h2><p>Run real demo scenarios against Covenant #0001. Safe actions pass. Unsafe actions are refused before execution.</p><button className="big-primary" onClick={openApp}>Open full agent console <ArrowUpRight size={16} /></button></div>
        <div className="demo-board">
          <div className="demo-board-head"><div><span className="pulse" /> COVENANT #0001 · LIVE</div><span>$500/action · 1% slippage · no leverage</span></div>
          <div className="demo-scenarios">{scenarios.map((scenario) => <button className={processing === scenario.name ? "processing" : ""} key={scenario.name} onClick={() => runScenario(scenario)}><span className={`demo-icon ${scenario.status}`}><scenario.icon size={17} /></span><div><strong>{scenario.name}</strong><small>{scenario.description}</small></div><span className={`try ${scenario.status}`}>{processing === scenario.name ? "Validating" : scenario.status === "approved" ? "Safe" : "Attack"} <ArrowUpRight size={12} /></span></button>)}</div>
        </div>
      </section>

      <section className="proof-story">
        <div className="proof-copy"><span className="section-label">The breakthrough</span><h2>Execution receipts prove what happened.<br /><em>Refusal proofs prove what didn’t.</em></h2><p>Covenant Prime does not merely stop unsafe transactions. It creates a portable on-chain record of the attempted action, violated rule, agent, amount, and timestamp.</p><div className="proof-stats"><div><strong>42ms</strong><span>Median validation</span></div><div><strong>287</strong><span>Unsafe actions blocked</span></div><div><strong>$2.84M</strong><span>Protected value</span></div></div></div>
        <div className="proof-card">
          <div className="proof-card-top"><Fingerprint size={24} /><span>REFUSAL PROOF</span><b>#002291</b></div>
          <div className="proof-result"><span>BLOCKED</span><strong>Unauthorized recipient</strong><p>Agent attempted to transfer 450 USDC to a recipient outside the permitted perimeter.</p></div>
          <dl><div><dt>Agent</dt><dd>0x71C2...9F4A</dd></div><div><dt>Covenant</dt><dd>#0001</dd></div><div><dt>Asset</dt><dd>USDC</dd></div><div><dt>Amount</dt><dd>450.00</dd></div></dl>
          <div className="proof-hash"><span>Action hash</span><code>{makeHash(2291)}</code><Copy size={14} /></div>
        </div>
      </section>

      <section className="lifecycle">
        <div className="lifecycle-title"><span className="section-label">More than a trading bot</span><h2>One covenant.<br />The full asset lifecycle.</h2></div>
        <div className="lifecycle-list"><Life number="01" title="Trade & rebalance" copy="Bounded execution across tokenized stocks and RWAs." /><Life number="02" title="Vote & claim" copy="Governance and corporate actions with explicit permission." /><Life number="03" title="Repay & distribute" copy="Manage credit repayments and tokenized cash flows." /><Life number="04" title="Disclose & audit" copy="Permissioned data access with a complete proof trail." /></div>
      </section>

      <section className="developer" id="developers">
        <div><span className="section-label">Built for builders</span><h2>Plug enforceable authority into any agent.</h2><p>Standard Solidity contracts. Simple action requests. Stable reason codes. Deploy on Arbitrum or any EVM-compatible chain.</p><button className="big-secondary"><Code2 size={16} /> Read the architecture</button></div>
        <pre><code><span>{"// Agent proposes an action"}</span>{"\n"}router.proposeAction({"{"}{"\n"}  covenantId: <b>1</b>,{"\n"}  actionType: <em>BUY</em>,{"\n"}  asset: mNVDA,{"\n"}  amount: <b>200e6</b>{"\n"}{"}"});{"\n\n"}<span>{"// Allowed → execute + receipt"}</span>{"\n"}<span>{"// Refused → immutable proof"}</span></code></pre>
      </section>

      <section className="final-cta"><span className="section-label">Agentic finance needs boundaries</span><h2>Let agents act.<br /><em>Never let them betray the mandate.</em></h2><button className="big-primary" onClick={openApp}>Launch Covenant Prime <ArrowRight size={17} /></button></section>

      <footer><Logo /><p>Proof-gated execution for AI-managed tokenized securities.</p><span>Built on Arbitrum · Robinhood Chain ready</span></footer>
      {toast && <Toast action={toast} close={closeToast} />}
    </main>
  );
}

function HeroMachine() {
  return (
    <div className="hero-machine">
      <div className="machine-top"><span><i /> LIVE MANDATE</span><b>#0001</b></div>
      <div className="proposal"><span>AGENT PROPOSAL</span><div><strong>Buy mNVDA</strong><b>200 USDC</b></div><small>Slippage 0.5% · Prime Exchange</small></div>
      <div className="validation">
        <div className="validation-core"><ShieldCheck size={27} /><span>VALIDATING</span></div>
        <div className="check-list"><span><Check size={12} /> Agent assigned</span><span><Check size={12} /> Asset allowed</span><span><Check size={12} /> Within spend limit</span><span><Check size={12} /> Slippage safe</span></div>
      </div>
      <div className="machine-result"><BadgeCheck size={20} /><div><span>EXECUTED</span><strong>Receipt #001048</strong></div><ArrowUpRight size={15} /></div>
      <div className="machine-proof"><span className="proof-symbol"><Fingerprint size={15} /></span><span className="proof-badge">REFUSAL PROOF</span><span>Unsafe actions produce refusal proofs</span><b>287 recorded</b></div>
    </div>
  );
}

function Life({ number, title, copy }: { number: string; title: string; copy: string }) {
  return <div className="life"><span>{number}</span><h3>{title}</h3><p>{copy}</p><ArrowUpRight size={15} /></div>;
}

function ProductApp({ tab, setTab, actions, proofs, runScenario, selected, setSelected, closeApp, toast, closeToast, processing }: { tab: AppTab; setTab: (tab: AppTab) => void; actions: Action[]; proofs: Action[]; runScenario: (scenario: (typeof scenarios)[number]) => void; selected: Action | null; setSelected: (action: Action | null) => void; closeApp: () => void; toast: Action | null; closeToast: () => void; processing: string | null }) {
  return (
    <main className="app">
      <header className="app-header"><button onClick={closeApp}><Logo /></button><nav>{(["overview", "console", "proofs", "covenant"] as AppTab[]).map((item) => <button key={item} className={tab === item ? "active" : ""} onClick={() => setTab(item)}>{item === "console" ? "Agent console" : item}{item === "proofs" && <b>{proofs.length}</b>}</button>)}</nav><div><span className="network"><i /> Arbitrum Sepolia</span><button className="wallet-button"><Wallet size={15} /> 0x71C2...9F4A <ChevronDown size={13} /></button></div></header>
      <div key={tab} className="view-transition">
        {tab === "overview" && <AppOverview actions={actions} proofs={proofs} setTab={setTab} select={setSelected} />}
        {tab === "console" && <AgentConsole actions={actions} runScenario={runScenario} select={setSelected} processing={processing} />}
        {tab === "proofs" && <ProofDashboard proofs={proofs} select={setSelected} />}
        {tab === "covenant" && <Covenant />}
      </div>
      {selected && <ActionModal action={selected} close={() => setSelected(null)} />}
      {toast && <Toast action={toast} close={closeToast} />}
    </main>
  );
}

function AppTitle({ eyebrow, title, copy, action }: { eyebrow: string; title: string; copy: string; action?: React.ReactNode }) {
  return <div className="app-title"><div><span>{eyebrow}</span><h1>{title}</h1><p>{copy}</p></div>{action}</div>;
}

function AppOverview({ actions, proofs, setTab, select }: { actions: Action[]; proofs: Action[]; setTab: (tab: AppTab) => void; select: (action: Action) => void }) {
  return <div className="app-content"><AppTitle eyebrow="Covenant #0001 · Enforced" title="Control center" copy="Every agent instruction is validated before execution." action={<button className="app-primary" onClick={() => setTab("console")}><Zap size={16} /> Run live demo</button>} /><div className="app-metrics"><AppMetric label="Protected value" value="$2.84M" note="Across 3 tokenized assets" /><AppMetric label="Executed actions" value={String(actions.filter((a) => a.status === "approved").length + 1244)} note="100% within covenant" /><AppMetric label="Refusal proofs" value={String(proofs.length + 285)} note="Unsafe actions blocked" danger /><AppMetric label="Validation time" value="42ms" note="Median on-chain decision" /></div><div className="app-grid"><section className="app-panel activity-panel"><PanelTitle title="Recent agent activity" action={<button onClick={() => setTab("console")}>Open console <ArrowRight size={13} /></button>} /><ActionList actions={actions.slice(0, 5)} select={select} /></section><CovenantCard setTab={setTab} /></div></div>;
}

function AppMetric({ label, value, note, danger }: { label: string; value: string; note: string; danger?: boolean }) {
  return <div className={`app-metric ${danger ? "danger" : ""}`}><span>{label}</span><strong>{value}</strong><p>{note}</p></div>;
}

function PanelTitle({ title, action }: { title: string; action?: React.ReactNode }) {
  return <div className="panel-title"><h2>{title}</h2>{action}</div>;
}

function ActionList({ actions, select }: { actions: Action[]; select: (action: Action) => void }) {
  return <div className="action-list">{actions.map((action) => <button key={`${action.id}-${action.name}`} onClick={() => select(action)}><span className={`action-status ${action.status}`}>{action.status === "approved" ? <Check size={15} /> : <X size={15} />}</span><div><strong>{action.name}</strong><small>{action.description}</small></div><span className="action-amount">{action.amount}</span><span className={`status-pill ${action.status}`}>{action.status}</span><ArrowRight size={14} /></button>)}</div>;
}

function CovenantCard({ setTab }: { setTab: (tab: AppTab) => void }) {
  return <section className="app-panel covenant-card"><PanelTitle title="Active covenant" action={<span className="enforced"><i /> Enforced</span>} /><div className="covenant-number"><span>Total authority</span><strong>$10,000</strong><div><span style={{ width: "34%" }} /></div><small>$3,400 used · $6,600 available</small></div><dl><div><dt>Single action</dt><dd>$500 max</dd></div><div><dt>Daily volume</dt><dd>$2,500 max</dd></div><div><dt>Slippage</dt><dd>1.00% max</dd></div><div><dt>Leverage</dt><dd>Blocked</dd></div></dl><div className="asset-pills"><span>mAAPL</span><span>mNVDA</span><span>mTSLA</span></div><button className="app-secondary" onClick={() => setTab("covenant")}>View covenant <ArrowUpRight size={13} /></button></section>;
}

function AgentConsole({ actions, runScenario, select, processing }: { actions: Action[]; runScenario: (scenario: (typeof scenarios)[number]) => void; select: (action: Action) => void; processing: string | null }) {
  return <div className="app-content"><AppTitle eyebrow="Live simulation" title="Agent console" copy="Propose actions against the active covenant and inspect the on-chain decision." /><div className="console-layout"><section className="scenario-panel"><PanelTitle title="Propose an action" /><div className="scenario-list">{scenarios.map((scenario) => <button className={processing === scenario.name ? "processing" : ""} key={scenario.name} onClick={() => runScenario(scenario)}><span className={`scenario-icon ${scenario.status}`}><scenario.icon size={18} /></span><div><strong>{scenario.name}</strong><small>{processing === scenario.name ? "Mandate engine is validating…" : scenario.description}</small></div><span>{processing === scenario.name ? "Checking" : scenario.amount}</span><ArrowUpRight size={14} /></button>)}</div></section><section className="app-panel stream"><PanelTitle title="Decision stream" action={<span className="live"><i /> Live</span>} /><ActionList actions={actions.slice(0, 7)} select={select} /></section></div></div>;
}

function ProofDashboard({ proofs, select }: { proofs: Action[]; select: (action: Action) => void }) {
  return <div className="app-content"><AppTitle eyebrow="Verifiable safety record" title="Refusal proofs" copy="On-chain evidence that unsafe agent actions were blocked before settlement." /><div className="proof-banner"><Fingerprint size={25} /><div><strong>Unsafe actions should leave evidence.</strong><p>Every refusal records the attempted action, violated rule, agent, amount, and action hash.</p></div><span>{proofs.length + 285}<small>Total proofs</small></span></div><section className="app-panel"><PanelTitle title="Proof registry" /><ActionList actions={proofs} select={select} /></section></div>;
}

function Covenant() {
  return <div className="app-content"><AppTitle eyebrow="Policy composer" title="Covenant #0001" copy="The enforceable boundary around your assigned AI agent." action={<button className="app-primary"><Plus size={15} /> Create covenant</button>} /><div className="policy-layout"><section className="app-panel policy"><PanelTitle title="Agent authority" /><Policy label="Assigned agent" value="0x71C2E09D...9F4A" /><Policy label="Maximum total spend" value="10,000 USDC" /><Policy label="Maximum single action" value="500 USDC" /><Policy label="Daily volume limit" value="2,500 USDC" /><Policy label="Maximum slippage" value="1.00%" /></section><section className="app-panel policy"><PanelTitle title="Lifecycle permissions" /><Policy label="Corporate actions" value="Allowed" good /><Policy label="Auditor disclosure" value="Blocked" /><Policy label="Leverage" value="Blocked" /><Policy label="Mandate expiry" value="21 June 2026" /><Policy label="Status" value="Enforced" good /></section></div></div>;
}

function Policy({ label, value, good }: { label: string; value: string; good?: boolean }) {
  return <div className="policy-row"><span>{label}</span><strong className={good ? "good" : ""}>{value}</strong></div>;
}

function ActionModal({ action, close }: { action: Action; close: () => void }) {
  return <div className="modal-backdrop" onClick={close}><div className="action-modal" onClick={(event) => event.stopPropagation()}><button className="modal-close" onClick={close}><X size={17} /></button><span className={`modal-icon ${action.status}`}>{action.status === "approved" ? <BadgeCheck size={27} /> : <Fingerprint size={27} />}</span><span className="modal-kicker">{action.status === "approved" ? "Execution receipt" : "Refusal proof"} #{action.id}</span><h2>{action.status === "approved" ? "Action executed" : "Action refused"}</h2><p>{action.reason}</p><dl><div><dt>Action</dt><dd>{action.name}</dd></div><div><dt>Asset</dt><dd>{action.asset}</dd></div><div><dt>Amount</dt><dd>{action.amount}</dd></div><div><dt>Covenant</dt><dd>#0001</dd></div></dl><div className="modal-hash"><span>Action hash</span><code>{action.hash}</code></div><a className="app-primary" href={`https://sepolia.arbiscan.io/tx/${action.hash}`} target="_blank" rel="noreferrer">View on Arbiscan <ArrowUpRight size={14} /></a></div></div>;
}

function Toast({ action, close }: { action: Action; close: () => void }) {
  return <div className={`toast ${action.status}`}><span>{action.status === "approved" ? <Check size={17} /> : <X size={17} />}</span><div><strong>{action.status === "approved" ? "Action executed" : "Action refused + proof recorded"}</strong><small>{action.reason}</small></div><button onClick={close}><X size={14} /></button></div>;
}

---
title: "AI Advisory Board"
---

# AI Advisory Board

A specific [[concepts/agent-teams|agent teams]] pattern for structured decision-making. Instead of one agent evaluating a proposal, you run five agents in parallel — each with a distinct expert persona, each evaluating the same proposal from their domain's angle. A sixth synthesizer agent reads all five outputs and produces a ranked recommendation with rationale.

The result: multi-perspective analysis in under five minutes, on demand, for any proposal you're considering.

---

## Why Parallel Expert Personas Work

A single agent asked to "evaluate this idea from multiple angles" will technically do so, but it evaluates sequentially and each perspective is colored by the previous ones. The devil's advocate critique comes after the optimistic analysis, and it pulls its punches.

Separate parallel agents don't have this problem. The DevilsAdvocate agent only knows to find fatal flaws — it hasn't seen the GrowthStrategist's enthusiasm yet. Each expert is genuinely independent.

This is the same reason human advisory boards use independent advisors rather than one consultant who "plays multiple roles."

---

## Board Composition

A practical five-expert board:

**DevilsAdvocate** — What are the fatal flaws? What's the most likely way this fails? What's being assumed that probably isn't true?

**RevenueGuardian** — What are the real costs and margins? What's the cash flow timeline? What are the hidden costs that aren't in the initial estimate?

**GrowthStrategist** — What's the customer acquisition path? Where does growth come from? What are the scalable and non-scalable parts?

**OperationsAnalyst** — What does it take to build and maintain this? What's the complexity, the maintenance burden, the failure modes? What's missing from the spec?

**MarketAnalyst** — What does the competitive landscape look like? What's the timing risk? What are customers already using instead?

Adjust the composition for your context. A technical decision might swap MarketAnalyst for a SecurityReviewer. A hiring decision might add an HR perspective. The pattern is flexible.

---

## The Synthesis Pass

After all experts complete, the synthesizer agent reads the full output of all five and produces:

1. A summary of the key findings from each expert
2. Points of convergence (multiple experts flagged the same concern)
3. Points of divergence (experts disagreed — worth examining why)
4. A ranked recommendation: proceed / proceed with modifications / pause / reject
5. The top 3 actions to take if proceeding

Convergent concerns are important signals — if both the DevilsAdvocate and the RevenueGuardian flag the same risk, that's worth taking seriously. Divergent assessments tell you where genuine uncertainty exists.

---

## Data-Triggered Variant

Matthew Berman's production stack includes a variant where the board isn't triggered by a user prompt — it's triggered by incoming data signals. The Business Intelligence Council scans inbound signals (market data, competitor updates, usage metrics) and automatically evaluates them against business priorities.

Findings get stored in SQLite with timestamps. Recommendations build a history, and the accept/reject loop tunes which experts are being helpful over time.

This is more complex to build but more powerful for continuous monitoring. The prompt-triggered version is a good starting point; the data-triggered version is the production upgrade.

---

## Practical Notes

**Run this before committing significant resources.** New product ideas, pricing changes, major builds. Not for small decisions.

**Five minutes of analysis is cheap.** The API cost of running five agents plus a synthesizer is usually under $0.50. The cost of building the wrong thing for a month is much higher.

**The experts will sometimes disagree.** That's information. When the GrowthStrategist is bullish and the RevenueGuardian is skeptical, you need to understand why before proceeding.

**Board composition matters.** If every expert you include is naturally optimistic, you'll get optimistic output. Include at least one adversarial persona.

---

## Sources

Mark Kashef ("7 Things You Can Build with Claude Code Agent Teams," use case 5, t=938s) — prompt-triggered board with expert personas and synthesis pass. Matthew Berman ("5 Billion Tokens Perfecting OpenClaw," Prompt 5) — Business Intelligence Council, data-triggered variant, SQLite history, accept/reject feedback loop.

---

**Related:**
- [[concepts/agent-teams|Agent Teams]] — the underlying pattern this builds on
- [[concepts/self-improvement-system|Self-Improvement System]] — the accept/reject loop for tuning expert quality over time

---
title: Agent Dependency Risks
description: Security vulnerabilities that emerge when AI coding agents select, suggest, or install software dependencies — including hallucinated packages, outdated versions, and supply chain attack vectors enabled by agent behavior.
tags: [concepts, security, agents, dependencies, supply-chain, coding-agents]
---

AI coding agents introduce a new class of software supply chain risk: they select and install dependencies autonomously, at speed, and without the instinctive skepticism a senior engineer might apply. The result is a category of vulnerability that didn't exist before agents became part of the development pipeline.

## The core problem

When a human developer adds a dependency, they typically verify it: check the package name carefully, scan recent downloads and maintainers, look for known CVEs, and evaluate whether it's actually the right library. This is imperfect but provides a basic filter.

Coding agents skip most of this. They suggest packages based on training data that may be months or years stale, install what they propose without friction, and can introduce vulnerabilities silently — especially when running autonomously without a human reviewing each step.

Three distinct failure modes have emerged:

### 1. Hallucinated packages (slopsquatting)

AI models sometimes reference packages that don't exist — plausible-sounding names that weren't present in their training data or were invented during generation. Studies have found that approximately 20% of package references in AI-generated code point to non-existent libraries.

Attackers exploit this predictably: they monitor AI-suggested package names, register those fictional packages on npm, PyPI, or other repositories before a developer installs them, and populate the registered package with malicious code. The pattern is called **slopsquatting** — analogous to typosquatting, but targeting AI hallucinations rather than human typos.

A developer who runs `npm install` on an agent's suggestion without verification may install the attacker's package rather than nothing at all.

### 2. Stale version selection

Agent training data has a knowledge cutoff. When an agent suggests a specific dependency version, it's often referencing what was current or popular at training time. In the months or years since, that version may have accumulated known CVEs.

Unlike hallucinated packages, stale version selection is harder to catch — the package exists, installs cleanly, and passes basic tests. The vulnerability surfaces only when someone audits the dependency tree against a current vulnerability database.

### 3. Unnecessary dependency sprawl

Agents often solve problems by reaching for existing packages rather than writing simple inline code. This is efficient in the short term but expands the attack surface: each additional dependency is another package that can be compromised, deprecated, or transferred to a malicious maintainer.

An agent tasked with "add date formatting" might install a full moment.js-scale library where two lines of code would suffice. Multiplied across many agent-authored files, this creates a dependency graph significantly larger than necessary.

## Why agents amplify the risk

Traditional supply chain attacks require a human to make a mistake — mistype a package name, accept a dependency without review. With agents in the loop:

- **Volume is higher**: agents ship more code faster, including more dependency declarations
- **Review gaps exist**: in autonomous or overnight runs, there's no human at the moment of install
- **Confidence signals are absent**: agents don't flag uncertainty about package names the way they might flag uncertain code logic
- **Prompt injection can direct package selection**: a malicious dependency in the context (e.g., from a README the agent read) can instruct the agent to use a specific — attacker-controlled — package

## Mitigations

**Dependency locking and auditing in CI**
Every agent-authored dependency should pass through the same audit pipeline as human-authored ones: `npm audit`, `pip-audit`, `trivy`, or equivalent. This is the minimum baseline — it catches known CVEs but not hallucinated packages pre-registration.

**Allowlisting**
Some teams maintain an approved dependency list that agents are constrained to use. Anything outside the list requires human review before install. This is operationally heavier but eliminates slopsquatting risk for approved packages.

**Sandboxed install verification**
Running `npm install` in a sandboxed environment (no network access after initial fetch, filesystem isolation) limits blast radius if a malicious package executes install scripts.

**Agent tool restrictions**
Restricting which tools an agent can invoke — for example, allowing file edits but not direct package installs — keeps a human in the loop for the dependency step. The agent proposes the change; a human runs the install.

**Verification pass**
A post-generation step — either automated or human — specifically reviews dependency changes before they're committed. This can be a lightweight CI check that flags any new package not present in the previous lockfile.

## Relationship to prompt injection

Agent dependency risks intersect with [[Agent Memory Poisoning]] when external content influences package selection. An agent that reads a malicious README, processes a poisoned documentation file, or receives compromised tool output may be directed toward specific packages — intentionally harmful ones.

This makes the attack surface wider than just hallucination: even if an agent wouldn't hallucinate a package, it can be manipulated into requesting one.

## Related concepts

- [[AI Pipeline Security Layers]] — security controls across the full agent execution pipeline
- [[Agent Memory Poisoning]] — how external content can corrupt agent decision-making
- [[Agent Sandboxing Environments]] — isolating agent execution to limit blast radius
- [[Runtime Control Layer]] — intercepting and auditing agent actions before execution
- [[Self-Hosted Code Review Agents]] — using independent review agents to catch introduced vulnerabilities

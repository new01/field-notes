---
title: "AI Toolchain Dependency Poisoning: How the LiteLLM Backdoor Spread Through MCP and Agent Frameworks"
description: The LiteLLM supply chain compromise was discovered because an MCP plugin in Cursor crashed. A breakdown of how poisoned packages propagate through AI toolchains — MCP servers, agent frameworks, and IDE plugins — and why traditional detection failed.
tags: [concepts, security, supply-chain, mcp, litellm, agents, incident]
---

On March 24, 2026, Callum McMahon at FutureSearch was testing an MCP plugin in Cursor that pulled in LiteLLM as a transitive dependency. His machine became unresponsive and ran out of RAM. The cause turned out to be a backdoored version of LiteLLM (1.82.8) that contained a fork bomb — an unintentional bug in the malware itself.

The compromise was not found by security scanners, CVE feeds, or CI/CD checks. It was found because the malware crashed loudly enough for a developer to notice.

This page focuses on the propagation path — how a single poisoned PyPI package cascaded through MCP servers, agent frameworks, and IDE plugins — and what this reveals about the unique attack surface of AI toolchains. For the full incident breakdown, see [[concepts/litellm-supply-chain-compromise|LiteLLM Supply Chain Compromise]].

## How the fork bomb exposed the backdoor

Version 1.82.8 shipped with a malicious `litellm_init.pth` file at the wheel root. `.pth` files in Python execute automatically on interpreter startup — no import required. The payload spawned a child Python process via `subprocess.Popen`, but that child process also triggered the same `.pth` file, which spawned another child, and so on. Exponential process spawning. A textbook fork bomb.

McMahon's Cursor instance froze. He investigated, found the `.pth` file, and traced it to the litellm package. Within hours, the community had reverse-engineered the full three-stage payload: credential harvesting, Kubernetes lateral movement, and a persistent backdoor phoning home to `checkmarx[.]zone`.

The irony: if the malware had worked correctly, it would have silently exfiltrated credentials and established persistence without anyone noticing. The bug in the malware was the only reason it was caught quickly.

## The transitive dependency problem

LiteLLM was not a direct dependency for most affected users. It was pulled in transitively — by MCP servers, by agent orchestration frameworks, by IDE plugins. This is the core of the propagation story.

Within hours of disclosure, emergency security PRs were filed across the ecosystem:

- **DSPy** — LLM programming framework
- **MLflow** — ML experiment tracking
- **OpenHands** — autonomous coding agent
- **CrewAI** — multi-agent orchestration
- **Langwatch** — LLM observability
- **Arize Phoenix** — AI observability platform

These frameworks did not choose to trust the compromised code. They inherited it through their dependency trees. Their users — running agents, MCP servers, and IDE integrations — inherited it again.

According to Wiz, LiteLLM is present in 36% of cloud environments. It has approximately 3.4 million downloads per day. A poisoned version at this scale does not need to target anyone specifically. It targets everyone by default.

## Why MCP servers amplify the blast radius

MCP servers are particularly dangerous vectors for supply chain attacks, for three reasons:

**1. They consolidate credentials.** An MCP server that routes requests to multiple model providers holds API keys for all of them. LiteLLM is commonly used as the routing layer, meaning a compromise at this level exposes every provider credential in one place.

**2. They run with elevated access.** MCP servers expose tools — file systems, databases, code execution, external APIs. A compromised dependency inside an MCP server inherits whatever permissions the server has. If the server can read your codebase and execute shell commands, so can the malware.

**3. They hide in the dependency tree.** Most developers using Cursor, Claude Code, or other agent-powered IDEs do not audit the dependency trees of their MCP plugins. The plugin exposes a tool interface; what happens beneath that interface is opaque. LiteLLM can be three or four levels deep in the dependency graph, invisible to anyone who isn't actively looking.

The MCP ecosystem is young and moving fast. Between January and February 2026, over 30 CVEs were filed targeting MCP servers, clients, and infrastructure. BlueRock Security found that 36.7% of 7,000 surveyed MCP servers were potentially vulnerable to SSRF. Trend Micro found 492 MCP servers exposed to the internet with zero authentication. Qualys has characterized MCP servers as "the new shadow IT for AI" — they bind to localhost on random ports, hide behind reverse proxies, or embed in IDE plugins, evading traditional security visibility.

## The attack chain that made it possible

The LiteLLM compromise did not start with LiteLLM. It started with an unpinned GitHub Action.

1. **Late February**: Attacker `MegaGame10418` exploited a `pull_request_target` workflow vulnerability in Aqua Security's Trivy repository to steal CI bot credentials.
2. **March 19**: TeamPCP rewrote Git tags in `trivy-action`, pointing the v0.69.4 tag to a malicious release containing credential-harvesting code.
3. **March 23**: The same group compromised Checkmarx's KICS GitHub Action using identical infrastructure. They registered `checkmarx.zone` and `models.litellm.cloud` as C2 domains.
4. **March 24**: LiteLLM's CI/CD pipeline ran the poisoned Trivy action without version pinning. The malicious scanner exfiltrated the `PYPI_PUBLISH` token. Within hours, versions 1.82.7 and 1.82.8 were live on PyPI.

The attack targeted security tools specifically — vulnerability scanners and static analysis tools — because these tools have elevated pipeline access by design. They need broad filesystem access, network access, and often publishing credentials to do their jobs. Compromising a security tool gives you the keys to everything it protects.

## AI agents used in the attack itself

Snyk's analysis identified a component called "hackerbot-claw" deployed by TeamPCP — described as an AI agent used for automated targeting. This appears to be one of the first documented cases of an AI agent used operationally in a supply chain attack. The attackers used the same class of tools they were attacking.

## Why standard defenses failed

**Package signatures were valid.** The malicious packages were published using legitimate, stolen PyPI credentials. `pip install` verified the package as authentic because, from PyPI's perspective, it was uploaded by an authorized maintainer.

**Vulnerability scanners were compromised.** The very tools that should have detected the malicious payload — Trivy and KICS — were part of the attack chain. You cannot scan for compromise using a tool that is itself compromised.

**The `.pth` mechanism bypasses import-time checks.** Security tools that monitor `import` statements or hook into Python's import machinery miss `.pth` files entirely. They execute before any application code runs, at interpreter startup. CPython issue #113659 acknowledges this as a known vulnerability. No patch has been deployed.

**Disclosure spread through non-traditional channels.** The first reports appeared on r/LocalLLaMA, r/Python, and Hacker News — not through CVE feeds, security advisories, or vendor notifications. Teams relying on traditional security intelligence channels were among the last to know.

## Lessons for agent builders

**Audit transitive dependencies, not just direct imports.** Run `pip show litellm` even if you never explicitly installed it. Run `pipdeptree` or `uv pip tree` to see what pulled it in. If you run MCP servers, audit their full dependency trees.

**Pin CI/CD tooling by hash, not by tag.** Git tags are mutable. Semver ranges are mutable. Only content-addressed references (commit SHA, package hash) provide integrity guarantees. This applies to GitHub Actions, Docker base images, and PyPI packages alike.

**Treat MCP servers as a trust boundary.** An MCP plugin is not just a tool interface — it is a runtime with dependencies, credentials, and system access. Apply the same security scrutiny to MCP server dependencies that you would to production deployment dependencies.

**Monitor for `.pth` files.** Add `find $(python -c "import site; print(site.getsitepackages()[0])") -name "*.pth"` to your CI checks. Any unexpected `.pth` file in site-packages is a red flag.

**Watch non-traditional disclosure channels.** If you build on AI infrastructure, monitor r/LocalLLaMA, r/Python, Hacker News, and the GitHub issue trackers for your dependencies. The next incident will likely surface there before it hits the CVE databases.

## Related

- [[concepts/litellm-supply-chain-compromise|LiteLLM Supply Chain Compromise]] — full incident breakdown, IOCs, and mitigation steps
- [[concepts/mcp-security-gateways|MCP Security Gateways]] — proxy layers for enforcing policy on MCP tool calls
- [[concepts/agent-dependency-risks|Agent Dependency Risks]] — slopsquatting, stale versions, and dependency sprawl in AI agents
- [[concepts/ai-pipeline-security-layers|AI Pipeline Security Layers]] — defense-in-depth for agent infrastructure

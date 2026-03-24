---
title: "LiteLLM Supply Chain Compromise: What Agent Builders Need to Know"
description: On March 24, 2026, malicious versions of LiteLLM (1.82.7 and 1.82.8) were published to PyPI containing a multi-stage credential stealer, Kubernetes lateral movement toolkit, and persistent backdoor. A breakdown of what happened, who is affected, and how to respond.
tags: [concepts, security, supply-chain, litellm, incident]
---

On March 24, 2026, the threat actor group TeamPCP published two malicious versions of LiteLLM — versions 1.82.7 and 1.82.8 — to PyPI. The packages contained a multi-stage credential stealer, Kubernetes lateral movement toolkit, and persistent backdoor. No corresponding tags or releases exist on the official LiteLLM GitHub repository. The packages were uploaded directly to PyPI using compromised maintainer credentials.

LiteLLM has approximately 95-97 million monthly downloads and is a transitive dependency for many AI agent frameworks, MCP servers, and LLM orchestration tools. If you build or run AI agents, you need to check whether you're affected.

## What happened

The compromise originated through LiteLLM's CI/CD pipeline. LiteLLM used Aqua Security's Trivy vulnerability scanner without version pinning. TeamPCP had previously compromised Trivy (March 19) and Checkmarx's KICS GitHub Action (March 23). The compromised Trivy instance in LiteLLM's CI pipeline likely exfiltrated the maintainer's PyPI publishing credentials, which were then used to push the poisoned packages.

A commit pushed to one of the LiteLLM maintainer's forked repositories reads: "teampcp owns BerriAI."

### Timeline

| Date | Event |
|------|-------|
| March 1 | Aqua Security (Trivy maintainer) suffers initial breach |
| March 19 | TeamPCP compromises Trivy vulnerability scanner |
| March 23 | TeamPCP compromises Checkmarx KICS GitHub Action; attacker registers `litellm.cloud` domain |
| March 24, ~08:30 UTC | Malicious versions 1.82.7 and 1.82.8 published to PyPI |
| March 24, later | PyPI quarantines and suspends the entire litellm package |

## Affected versions

| Version | Delivery method | Activation trigger |
|---------|-----------------|-------------------|
| **1.82.7** | Payload injected into `litellm/proxy/proxy_server.py` (12 lines of obfuscated code) | On `import litellm` |
| **1.82.8** | Malicious `litellm_init.pth` file (34,628 bytes) at wheel root | **Any Python process startup** — no import needed |

The last confirmed clean version is **1.82.6**. The GitHub source repository is uncompromised — only the PyPI packages were poisoned.

Version 1.82.8 is especially dangerous: `.pth` files execute automatically when Python starts, meaning any Python process on a system with 1.82.8 installed was compromised, even if it never imported litellm.

## What the payload does

The attack is a three-stage operation:

**Stage 1 — Credential harvesting.** Collects SSH private keys, environment variables, AWS/GCP/Azure credentials, Kubernetes secrets and configs, Docker credentials, Git credentials, NPM tokens, shell history, database passwords, SSL private keys, CI/CD pipeline secrets, cloud metadata endpoint (IMDS) responses, and cryptocurrency wallets.

**Stage 2 — Kubernetes lateral movement.** If a Kubernetes service account token exists, reads cluster secrets across all namespaces and deploys privileged pods (`node-setup-*` in `kube-system`) to every node with host filesystem access.

**Stage 3 — Persistent backdoor.** Installs a systemd user service (`sysmon.service`) that polls `checkmarx[.]zone/raw` for additional binaries.

Harvested data is double base64-encoded, encrypted with AES-256-CBC (random session key, PBKDF2 derivation), session key encrypted with a hardcoded 4096-bit RSA public key, bundled as a tar archive, and exfiltrated to the C2 endpoint.

A notable bug: the v1.82.8 payload contained a fork bomb that caused exponential subprocess spawning, crashing affected machines — which ironically may have limited the stealth and reach of the attack.

## Indicators of compromise

**Files to check for:**
- `litellm_init.pth` in site-packages or pip/uv caches
- `~/.config/sysmon/sysmon.py` or `/root/.config/sysmon/sysmon.py`
- `~/.config/systemd/user/sysmon.service`

**Network indicators:**
- Connections to `models.litellm[.]cloud` (exfiltration endpoint — not the legitimate `litellm.ai`)
- Connections to `checkmarx[.]zone/raw` (C2 for additional binary downloads)
- POST requests with header `X-Filename: tpcp.tar.gz`

**Kubernetes indicators:**
- Rogue pods matching `node-setup-*` in `kube-system` namespace
- Privileged pods using `alpine:latest` with host filesystem mounts

## Mitigation steps

1. **Check if affected.** Run `pip show litellm` — if the version is 1.82.7 or 1.82.8, treat the entire system as fully compromised.
2. **Check caches.** `find ~/.cache/uv -name "litellm_init.pth"` and `pip cache purge`.
3. **Search for persistence.** Look for `sysmon.py`, `sysmon.service`, and `.pth` files in site-packages directories.
4. **Audit Kubernetes clusters.** Look for unauthorized `node-setup-*` pods in `kube-system`.
5. **Review egress logs.** Check for connections to `models.litellm[.]cloud` and `checkmarx[.]zone`.
6. **Rotate ALL credentials.** SSH keys, cloud provider credentials, API keys, database passwords, Kubernetes secrets, tokens — everything on the affected system. Assume full credential compromise.
7. **Remove and reinstall.** Uninstall litellm, purge pip/uv caches. Pin to 1.82.6 or wait for a verified clean release.
8. **Audit CI/CD pipelines.** Check for unpinned Trivy and KICS usage during the compromise window (March 1–24).

The LiteLLM team has engaged Google Mandiant for investigation. No new releases will be published until security is verified. As of March 24, no CVE has been assigned.

## Why this matters for agent builders

LiteLLM is one of the most widely used LLM proxy libraries. It sits between your agent code and your model providers — which means it has access to every API key, every prompt, and every response. A compromise at this layer is about as bad as it gets for an AI agent deployment.

This incident is a textbook example of why [[concepts/supply-chain-security|supply chain security]] matters for AI infrastructure:

- **Transitive dependency risk.** Many frameworks pull in litellm without users realizing it. Check your dependency tree, not just your direct imports.
- **CI/CD as attack surface.** The breach didn't start with litellm — it started with an unpinned vulnerability scanner in CI. Pin your CI tooling versions. Use hash verification for actions and dependencies.
- **PyPI trust model.** PyPI package ownership is a single point of failure. A compromised maintainer credential means arbitrary code execution on every machine that installs the package.
- **`.pth` file abuse.** Version 1.82.8 demonstrated that a malicious `.pth` file runs on any Python process startup, not just when the package is imported. This is a known Python packaging footgun that most developers aren't aware of.

If you run [[concepts/autonomous-agents|autonomous agents]] in production — especially with cloud credentials and Kubernetes access — audit your LiteLLM version immediately and rotate credentials if there's any doubt.

## Related

- [[concepts/supply-chain-security|Supply Chain Security]] — defense-in-depth for AI agent dependencies
- [[concepts/autonomous-agents|Autonomous Agents]] — implications for unattended agent deployments
- [[concepts/agent-security-model|Agent Security Model]] — why the trust boundary around agent dependencies matters

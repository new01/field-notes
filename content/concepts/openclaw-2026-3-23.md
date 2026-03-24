---
title: OpenClaw 2026.3.23 — Browser Reliability, ClawHub Auth, and Operational Hardening
description: A review of the 2026.3.23 release — focused on stability and reliability improvements across browser session management, ClawHub credential resolution, model pricing, and gateway supervision.
tags: [concepts, openclaw, browser, clawhub, release, stability]
---

OpenClaw 2026.3.23 is a stability release. There are no headline features — this one is about fixing things that worked in demos but broke in production, and closing gaps that only show up after days of continuous operation. Three themes dominate: browser session attachment reliability on macOS, ClawHub credential handling on macOS, and a cluster of operational fixes for gateway supervision, model defaults, and plugin lifecycle.

## Browser session attachment — fixing the macOS Chrome attach loop

The most impactful fix in this release for interactive use is the Chrome MCP attach behavior change.

**The problem:** When an agent connected to Chrome via the `existing-session` browser profile on macOS, the gateway was declaring the connection ready as soon as the Chrome MCP handshake completed. This was too early — the browser tab hadn't become fully usable yet. The result was repeated timeout errors and unnecessary consent prompts, making Chrome-attached agents unreliable for anything that required immediate browser interaction.

**The fix:** OpenClaw now waits for existing-session browser tabs to become usable after attach before considering the connection live. This means the agent waits a bit longer before announcing ready, but then actually works reliably rather than racing into a tab that's still initializing.

**The related CDP fix:** On slower headless Linux setups, a second-run `browser start` or `browser open` call would sometimes fail. The root cause was that OpenClaw wasn't checking whether a loopback browser was already running before deciding to relaunch — it would miss the initial reachability check and fall into relaunch detection unnecessarily. The fix makes OpenClaw reuse an already-running loopback browser after a short initial miss rather than immediately attempting relaunch.

Together these two fixes address the most common browser agent reliability complaints on macOS and slow headless Linux. If you're running browser-assisted agents and they've been flaky, updating to 2026.3.23 is worth doing.

## ClawHub authentication on macOS — skill browsing now works

ClawHub is OpenClaw's skill marketplace. If you're signed in to ClawHub on macOS, skills should be browseable and installable without extra authentication steps. In practice, this was broken.

The root cause was dual: OpenClaw wasn't reading the ClawHub login token from the macOS Application Support path where it's saved after `openclaw skills` authentication, and the gateway's skill-browsing API requests were falling through to unauthenticated mode instead of using the signed-in token. The result was either 429 (rate-limited unauthenticated requests) or empty skill lists even when the user was signed in.

Three related fixes address this together:
- Read the local ClawHub login from the macOS Application Support path (and still honor XDG on macOS for non-default setups)
- Honor macOS auth config *and* XDG auth paths for saved ClawHub credentials
- Resolve the local ClawHub auth token for gateway skill-browsing requests and switch browse-all to search so it hits the correct authenticated endpoint

After this fix, `openclaw skills` commands and the Control UI skill browser should stay authenticated through normal use without requiring periodic re-sign-in.

## Model defaults: Mistral, web_search, OpenRouter pricing

**Mistral max-token fix** — Mistral's API was returning HTTP 422 errors for new users. The cause: OpenClaw's bundled Mistral defaults carried context-window-sized output limits, which Mistral's API rejects as invalid. The fix lowers bundled Mistral max-token defaults to safe output budgets and adds a `openclaw doctor --fix` repair that updates old persisted configs with the same oversize limits. If you have a Mistral setup that's been throwing 422s, run `openclaw doctor --fix` after updating.

**web_search provider selection** — a subtle but consequential bug: when `web_search` was configured to use a specific provider, agent turns were sometimes using the stale/default provider selection instead of the active runtime config. Effectively, configuring a custom web search provider in some setups did nothing. This is now fixed to use the active runtime web_search provider.

**OpenRouter auto pricing loop** — the `openrouter/auto` model route was causing the pricing refresh to recurse indefinitely during gateway bootstrap. This prevented `openrouter/auto` pricing from populating, which meant `usage.cost` showed zero for auto-routed requests. The fix stops the recursion; pricing caches correctly now.

## Plugin lifecycle: LanceDB bootstrap and stale plugin warnings

**memory-lancedb** — the `plugins.slots.memory="memory-lancedb"` configuration was broken for global npm installs. LanceDB is a bundled plugin that requires runtime initialization on first use, but the gateway wasn't bootstrapping it from plugin runtime state — it expected the npm install to have already done the setup. On global npm installs where LanceDB isn't co-located, this silently failed. The fix bootstraps LanceDB into plugin runtime state on first use when it isn't already installed. If you've been trying to use LanceDB-backed memory and seeing silent failures, this should unblock it.

**Stale plugin warnings vs. errors** — when a plugin listed in `plugins.allow` wasn't installed locally (for example after an npm reinstall that dropped a plugin), OpenClaw was throwing a fatal config error. This blocked `plugins install`, `doctor --fix`, and `status` — the exact commands you'd use to recover from the situation. The fix treats stale unknown plugin IDs as warnings instead of errors, so recovery commands can still run. This is a meaningful operational improvement: the failure mode no longer traps users in a state where fixing requires manual config editing.

## Gateway supervision: stop crash-looping under launchd and systemd

When a gateway is already running and a second process tries to start, there's a lock conflict. Previously this caused the new process to exit as a failure — which, under launchd or systemd with `KeepAlive` or `Restart=always`, triggered an immediate restart loop. The supervision system would spin trying to start a gateway that kept "failing" due to the lock, while the actual healthy gateway was running fine.

The fix keeps the conflicting process in a retry wait instead of exiting as a failure. Under supervision, this means the new process waits gracefully until the running gateway either releases the lock or terminates, then takes over. No more crash loops from lock conflicts on system restart or update.

A related fix addresses false gateway probe timeouts: when a gateway was running and the `gateway status` probe successfully connected but post-connect detail RPCs were still loading, the gateway was sometimes reported as unreachable. The fix requires a successful RPC response before reporting reachable, but correctly distinguishes "connected but slow" from "dead" — slow devices now report a reachable RPC failure instead of a false negative.

## message tool: Discord and Feishu media fixes

A schema validation tightening in a recent release accidentally made `components` for Discord and `blocks` for Slack required fields in message tool calls. This caused pin/unpin/react flows to fail validation when those optional fields weren't provided, and broke Feishu `message(..., media=...)` sends that weren't going through the outbound media path. Both are fixed: `components` and `blocks` are optional again, and Feishu file/image attachments route correctly through the media send path.

## Subagent timing fix

A race condition in subagent completion handling: when a worker finished quickly, its completion event was sometimes being reported as a timeout because the check was against a stale runtime snapshot rather than the latest one. Fast-finishing workers could show as timed out in the gateway logs and session output even when they succeeded. The fix rechecks timed-out worker waits against the latest runtime snapshot before sending completion events.

---

2026.3.23 won't show up on a feature list. But if you've been dealing with flaky Chrome attachment, broken ClawHub skill browsing, Mistral 422s, OpenRouter pricing showing zero, or gateway crash loops under supervision — this release fixes all of those. The stability investment here is the kind that makes everything else work more reliably.

## Related

- [[concepts/agent-memory-systems|Agent Memory Systems]] — context for the LanceDB memory plugin this release unblocks
- [[concepts/agent-skill-packages|Agent Skill Packages]] — how ClawHub skills are packaged and installed
- [[concepts/openclaw-2026-3-11|OpenClaw 2026.3.11]] — previous release with major security hardening and ACP session continuity

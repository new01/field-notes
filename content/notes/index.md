---
title: "Notes"
---

# Notes

Things we've learned building with OpenClaw — raw insights from real automation work.

Not polished tutorials. Not beginner guides. Just the patterns and mental models that actually matter when you're building autonomous systems seriously.

---

## Recent

### [[agent-teams|Agent Teams]]
A pattern where a single prompt spawns multiple specialized subagents working in parallel, each handling a distinct slice of a larger task. The coordination is handled internally — the user writes one prompt and the system figures out the rest.

### [[brains-and-muscles|Brains and Muscles]]
The foundational model for understanding agent architecture: the brain is the LLM that handles reasoning; the muscles are the tools and integrations that let the agent take real-world actions. Simple framing, surprisingly useful for debugging and planning.

### [[notification-batching|Notification Batching]]
A three-tier queuing system for all outbound agent notifications that eliminates alert spam. Critical events deliver immediately. Everything else batches. Without this, every cron job becomes a ping.

---

More notes publish as work progresses. Watch [GitHub](https://github.com/cyne-wulf) for updates.

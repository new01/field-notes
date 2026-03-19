---
title: MCP Code Execution Pattern
description: Instead of passing every tool result through the model context window, agents write code that runs against MCP servers directly — reducing token usage by up to 98.7% while handling more tools and larger data payloads.
tags: [concepts, mcp, agents, token-efficiency, code-execution, patterns]
---

When an AI agent connects to MCP servers, the naive approach loads every tool definition upfront and pipes every intermediate result through the context window. At scale — dozens of servers, hundreds of tools, large documents — this becomes expensive and slow. Anthropic's code execution pattern inverts the model: instead of pulling tools and data into the model, the model writes code that runs against the tools directly.

The result is a 98.7% reduction in token usage on representative workloads (150,000 tokens down to ~2,000), confirmed independently by Cloudflare who calls the same pattern "Code Mode."

## The two problems it solves

### Tool definition overload

Most MCP clients load all tool definitions into the context window at the start of every conversation. A single MCP server might have 30–50 tools; an enterprise agent connected to Salesforce, Google Drive, Jira, Slack, and GitHub might expose hundreds. Each definition includes descriptions, parameter schemas, and return type docs — the kind of verbose metadata that adds up fast.

At 100 tools, you're paying context overhead before the user's request is even read.

### Intermediate result bloat

When an agent chains tool calls, results typically route back through the model. Ask an agent to "download the meeting transcript from Drive and attach it to the Salesforce lead" and the full transcript text flows through the context twice — once as the Drive tool result, once as the payload in the Salesforce write call. A two-hour meeting transcript can add 50,000+ tokens to a single task.

## How code execution solves both

The pattern exposes MCP servers as a filesystem of callable code files rather than as a flat list of tool definitions. Each tool becomes a typed function in a file:

```
servers/
├── google-drive/
│   ├── getDocument.ts
│   └── index.ts
├── salesforce/
│   ├── updateRecord.ts
│   └── index.ts
```

The agent discovers available servers by listing directories, then reads only the specific tool files it needs for the current task. Instead of 150,000 tokens of upfront tool definitions, it reads 2,000 tokens of targeted interfaces.

When the agent calls tools, it writes code that chains them together — the data flows between tool calls inside the execution environment, never passing back through the model context:

```typescript
import * as gdrive from './servers/google-drive';
import * as salesforce from './servers/salesforce';

const transcript = (await gdrive.getDocument({ documentId: 'abc123' })).content;
await salesforce.updateRecord({
  objectType: 'SalesMeeting',
  recordId: '00Q5f000001abcXYZ',
  data: { Notes: transcript }
});
```

The transcript moves directly from Drive to Salesforce inside the code execution environment. The model sees the intent and the result — not the 50,000-word document in the middle.

## Progressive disclosure: the key mechanism

Models are good at navigating filesystems. The pattern exploits this: rather than front-loading all context, the agent explores on demand.

A typical flow:
1. List `./servers/` to discover available integrations
2. Read the index files to understand what each server offers
3. Read specific tool files for the operations needed
4. Write and run the code

This is analogous to how a developer uses an SDK — you don't read every function definition before writing a feature. You navigate to what you need.

An alternative implementation adds a `search_tools` function that lets the agent query tool names by keyword, reducing exploration overhead further when dealing with very large server ecosystems.

## Privacy and state benefits

When intermediate data doesn't route through the model, it doesn't appear in logs or conversation history by default. For sensitive documents — contracts, HR records, financial data — this is a meaningful operational security improvement.

The execution environment also provides natural state: variables persist between steps without the model having to track them. Complex multi-step workflows become single code blocks rather than multi-turn conversations.

## What this changes architecturally

Traditional MCP architecture treats the model as the orchestrator — every tool call and result passes through it. Code execution pattern delegates orchestration to the execution environment:

```
Traditional:
Agent → [load all tool defs] → Model → tool call → result → Model → tool call → result → Model

Code Execution:
Agent → [load needed defs] → Model writes code → Execution env runs code → Model sees final output
```

The model moves from micromanager to architect: it decides what to do, writes the code to do it, and reviews the outcome.

## Limitations

The pattern requires a code execution environment. Not all agent frameworks or deployment contexts support running arbitrary code — this is more natural in agentic coding environments (Cursor, Claude Code, similar) than in pure chat-based agents.

Debugging is also different: errors surface as code execution failures rather than tool call errors, which requires the agent to handle exceptions in its generated code rather than relying on MCP error responses.

## Related

- [[concepts/mcp-protocol-adoption|MCP Protocol Adoption]] — ecosystem context for where MCP tooling stands
- [[concepts/mcp-security-gateways|MCP Security Gateways]] — policy enforcement at the MCP transport layer
- [[concepts/agent-budget-enforcement|Agent Budget Enforcement]] — token reduction as cost control
- [[concepts/agent-sandboxing-environments|Agent Sandboxing Environments]] — the execution environments this pattern runs inside
- [[concepts/multi-agent-context-scoping|Multi-Agent Context Scoping]] — related context efficiency strategies for agent teams

## Sources

Anthropic Engineering: "Code execution with MCP: Building more efficient agents" (2025). Cloudflare Blog: "Code Mode" findings on MCP token efficiency (2025). Daily session notes — 2026-03-19.

---
title: Agent UI Specification DSLs
description: Structured, text-based wireframing schemas that give AI coding agents a deterministic intermediate representation for UI generation — reducing hallucination, improving consistency, and enabling version control.
tags: [concepts, agents, ui, dsl, spec-driven-development, prompt-engineering, coding-agents]
---

Agent UI Specification DSLs are lightweight, structured text formats — typically Markdown-based — that define UI layouts, components, interactions, and design constraints in a form AI coding agents can parse with high accuracy. They sit between natural language intent and generated UI code, acting as an intermediate representation that constrains what the agent produces.

The central claim: agents hallucinate less when given a strict schema to follow than when given a natural language description of what to build.

## The problem they solve

AI agents generating UI code face three compounding failure modes:

**1. Underspecified prompts.** "Build a login page" produces wildly inconsistent results across runs — different layout choices, component hierarchies, field names, styling approaches. There's no source of truth.

**2. Visual spec impedance.** Figma files and PNG wireframes are high-fidelity but token-expensive to encode and difficult for agents to interpret accurately. Converting them to text loses structural information; providing them as images adds cost and imprecision.

**3. Hallucinated components.** Without explicit constraints, agents invent component APIs, prop names, and design system tokens that don't exist in the actual codebase — generating code that looks plausible but fails on import.

A structured DSL addresses all three by providing a parseable, version-controlled spec that the agent treats as ground truth.

## How it works

A Markdown UI DSL defines a syntax for describing UI structure. A spec file might describe:

```markdown
## Page: LoginPage
layout: centered
max-width: 400px

### Component: EmailField
  type: input
  label: "Email address"
  validation: required, email

### Component: PasswordField
  type: input
  subtype: password
  label: "Password"
  validation: required, min-length:8

### Component: SubmitButton
  type: button
  label: "Sign in"
  style: primary
  action: submit(LoginForm)
```

The agent reads this spec, maps each component to the design system's actual component library, and generates code against the spec rather than reasoning from scratch. Because the spec names real components and uses known props, hallucination opportunities are narrowed.

The workflow typically follows spec-driven development (SDD):
1. A product manager or designer writes a `.ui.md` spec file
2. The agent reads the spec, resolves component mappings against `design-system.md`
3. Code is generated to match the spec exactly
4. Changes to UI go through the spec first, not directly to code

## Why Markdown specifically

Markdown was chosen over JSON or YAML in most implementations for several reasons:

- **Human readable** — product managers can write and review specs without developer involvement
- **LLM-native** — agents are trained on enormous amounts of Markdown and parse it fluently
- **Diff-friendly** — spec files version-control cleanly in git; changes are reviewable in PRs
- **Low ceremony** — no schema validation tooling required; the spec is its own documentation

The tradeoff is that Markdown DSLs sacrifice the strict machine-parseability of JSON Schema. In practice, agents handle the ambiguity well enough that the human-readability benefit wins.

## Integration with agent skill systems

Markdown UI DSLs are typically delivered as agent skills — a `SKILL.md` file that defines the DSL syntax and instructs the agent how to use it. The agent loads the skill when UI work is requested, gaining both the parsing rules and the generation constraints.

This follows the same pattern as [[Skill-Based Agent Architecture]]: capabilities injected at task time rather than baked into the base system prompt.

A `design-system.md` companion file maps DSL component names to actual library components:

```markdown
## Component Map
- button[style=primary] → <Button variant="contained" color="primary">
- input[subtype=password] → <PasswordInput />
- layout[centered] → <Box display="flex" justifyContent="center">
```

The agent resolves against this map before generating, eliminating the hallucinated-import class of errors.

## Relationship to prompt governance

Agent UI DSLs are a specific application of structured prompt inputs — where the "prompt" for a UI generation task is a formal spec rather than natural language. This connects to the broader pattern in [[Prompt File Governance]]: treating agent inputs as version-controlled artifacts with defined structure, not ephemeral chat messages.

The spec file becomes the canonical source of truth. If the UI changes, the spec changes first. The agent is a rendering engine for the spec, not the decision-maker about what to build.

## Limitations

- **Spec maintenance overhead** — every UI change requires updating the spec file. Teams that ship fast find this friction real.
- **Coverage gaps** — complex interactions (drag-and-drop, animated transitions, conditional visibility) are hard to express in flat Markdown syntax.
- **No runtime validation** — the DSL doesn't enforce that generated code actually matches the spec; that requires a review step or test coverage.
- **Framework coupling** — the design-system mapping is tightly coupled to one component library. Migrating frameworks means rewriting the mapping file.

## Related concepts

- [[Prompt File Governance]] — treating agent inputs as structured, version-controlled artifacts
- [[Agent-Native Source Code]] — designing codebases for agent parseability
- [[Skill-Based Agent Architecture]] — capability injection at task time
- [[Prompt Enrichment Architecture]] — transforming rough inputs into structured agent context
- [[Input Validation in Skills]] — constraining agent inputs at the skill boundary
- [[Agent Self-Review Loop]] — using secondary agents to verify generated outputs against specs

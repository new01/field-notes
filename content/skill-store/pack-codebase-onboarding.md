---
title: "Skill Pack: Codebase Onboarding Kit"
description: Generate architecture maps, dependency graphs, and onboarding docs for any codebase.
tags: [skill-store, skill-pack, onboarding, documentation, openclaw]
---

# Skill Pack: Codebase Onboarding Kit

A pack of 3 skills for teams that onboard new developers regularly. Point your agent at a codebase and get a structured onboarding document, architecture map, and dependency analysis — in minutes instead of days.

---

## What's Inside

### 1. Architecture Mapper
Scans a repository's directory structure, entry points, and import graph to produce a plain-text architecture overview. Identifies layers (API, business logic, data), key abstractions, and the request lifecycle. Output is a markdown doc ready to drop into your wiki.

### 2. Dependency Analyzer
Reads package manifests (package.json, requirements.txt, Cargo.toml, go.mod) and produces a categorized dependency report: direct vs transitive, outdated packages, known CVEs (via OSV database), and license compatibility summary.

### 3. Onboarding Doc Generator
Combines the architecture map and dependency analysis with README content and inline comments to produce a structured onboarding guide. Includes: what the project does, how to set up a dev environment, where to find key code, and common workflows.

---

## Details

| Field | Value |
|-------|-------|
| Price | $14 one-time |
| Skills included | 3 |
| Target user | Team leads, engineering managers, open source maintainers |
| Requires | OpenClaw v0.2+ |
| Install | `openclaw skill install store:codebase-onboarding` |

---

## Pack Structure

```
codebase-onboarding/
├── SKILL.md                  # Pack manifest and metadata
├── architecture-mapper/
│   └── SKILL.md              # Architecture scanning instructions
├── dependency-analyzer/
│   └── SKILL.md              # Dependency audit instructions
├── onboarding-doc/
│   └── SKILL.md              # Onboarding document generation
└── tests/
    ├── architecture.test.md
    └── dependency.test.md
```

---

## Related

- [[skill-store/index|OpenClaw Skill Store]]
- [[concepts/skill-based-agent-architecture|Skill-Based Agent Architecture]]

---
title: "Skill Pack: Git Workflow Automator"
description: Automate PR reviews, commit messages, and branch management with OpenClaw skills.
tags: [skill-store, skill-pack, git, automation, openclaw]
---

# Skill Pack: Git Workflow Automator

A pack of 4 skills that automate the most repetitive parts of Git-based development workflows. Built for developers and teams who use OpenClaw daily and want their agent to handle Git hygiene without being told.

---

## What's Inside

### 1. PR Review Skill
Reads a pull request diff, identifies issues (bugs, style violations, missing tests), and posts a structured review comment. Configurable severity thresholds.

### 2. Commit Message Generator
Analyzes staged changes and generates a conventional commit message. Follows the repository's existing commit style by reading recent history. Supports Conventional Commits, Angular, and custom formats.

### 3. Branch Cleanup Skill
Identifies merged and stale branches (configurable age threshold), lists them for confirmation, and deletes on approval. Never touches protected branches.

### 4. Merge Conflict Resolver
Detects merge conflicts, reads both sides plus the common ancestor, and proposes a resolution with an explanation of the choices made. Always requires human approval before applying.

---

## Details

| Field | Value |
|-------|-------|
| Price | $19 one-time |
| Skills included | 4 |
| Target user | Solo devs and small teams using Git daily |
| Requires | OpenClaw v0.2+, Git |
| Install | `openclaw skill install store:git-workflow-automator` |

---

## Pack Structure

```
git-workflow-automator/
├── SKILL.md              # Pack manifest and metadata
├── pr-review/
│   └── SKILL.md          # PR review instructions
├── commit-message/
│   └── SKILL.md          # Commit message generation
├── branch-cleanup/
│   └── SKILL.md          # Stale branch detection + cleanup
├── merge-conflict/
│   └── SKILL.md          # Conflict resolution logic
└── tests/
    ├── pr-review.test.md
    ├── commit-message.test.md
    └── branch-cleanup.test.md
```

---

## Related

- [[skill-store/index|OpenClaw Skill Store]]
- [[concepts/skill-based-agent-architecture|Skill-Based Agent Architecture]]

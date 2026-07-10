---
description: Summarize the whole plan/file and proposed changes, then recommend a reasoning effort for implementing it
argument-hint: [plan file | files/dirs | task description | (blank = infer the backlog)]
---

## Target

$ARGUMENTS

## Instructions

Scope the work described (or implied) by **Target** above *as a whole*, then recommend how to implement it. Interpret Target flexibly:

- **Blank** — infer the full backlog from the project's own sources (e.g. `TODO.md`, an open plan doc, or `git status`/recent commits). State explicitly what you inferred and why.
- **A plan file or doc** (e.g. `PLAN.md`, a path) — read it and scope all of its unstarted work together.
- **One or more files/dirs** — read them and scope the changes implied across them.
- **A free-form task description** — scope it.

Treat the entire plan/file as a single unit of work — not just the next chunk or step.

Do **not** start implementing. Produce only the following summary:

### 1. Scope
A short paragraph: what the plan accomplishes overall and why.

### 2. Proposed changes
A concrete, file-level list of the edits the plan entails — paths, functions/sections touched, and the nature of each change. Note anything you'd verify or any open questions that block a clean implementation.

### 3. Recommended reasoning effort
Recommend one `model_reasoning_effort` level for implementing the *whole plan*, with a one-line justification tied to its overall complexity and risk.

- **Effort:** `minimal`/`low` (mechanical), `medium` (standard), `high` (multi-file or subtle logic), `xhigh` (deep reasoning, high blast radius).
- Optionally note if the work warrants a heavier model than the configured default.

Give the recommendation as a copy-pasteable line, e.g. `→ model_reasoning_effort: high`.

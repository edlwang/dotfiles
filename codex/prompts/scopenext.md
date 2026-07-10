---
description: Summarize the next task and proposed changes, then recommend a reasoning effort for the implementation
argument-hint: [task description | plan file | files/dirs | (blank = infer next task)]
---

## Target

$ARGUMENTS

## Instructions

Scope the work described (or implied) by **Target** above, then recommend how to implement it. Interpret Target flexibly:

- **Blank** — infer the next task from the project's own backlog (e.g. `TODO.md`, an open plan doc, or `git status`/recent commits). State explicitly what you inferred and why.
- **A free-form task description** — scope that task.
- **A plan file or doc** (e.g. `PLAN.md`, a path) — read it and scope the next unstarted step.
- **One or more files/dirs** — read them and scope the change implied for them, asking what outcome is wanted only if it's genuinely ambiguous.

Do **not** start implementing. Produce only the following summary:

### 1. Task
One or two sentences: what is being done and why.

### 2. Proposed changes
A concrete, file-level list of the edits you'd make — paths, functions/sections touched, and the nature of each change. Note anything you'd verify or any open questions that block a clean implementation.

### 3. Recommended reasoning effort
Recommend one `model_reasoning_effort` level for the *implementation* step, with a one-line justification tied to the task's complexity and risk.

- **Effort:** `minimal`/`low` (mechanical), `medium` (standard), `high` (multi-file or subtle logic), `xhigh` (deep reasoning, high blast radius).
- Optionally note if the work warrants a heavier model than the configured default.

Give the recommendation as a copy-pasteable line, e.g. `→ model_reasoning_effort: high`.

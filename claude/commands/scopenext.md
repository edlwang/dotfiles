---
description: Summarize the next task and proposed changes, then recommend a model and effort level for the implementation
argument-hint: [task description | plan file | files/dirs | (blank = infer next task)]
allowed-tools: Read, Grep, Glob, Bash(git status:*), Bash(git log:*), Bash(git diff:*)
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

### 3. Recommended model & effort
Recommend one model and one effort level for the *implementation* step, with a one-line justification tied to the task's complexity and risk.

- **Models:** `claude-opus-4-8` (hardest reasoning/architecture), `claude-sonnet-4-6` (balanced default), `claude-haiku-4-5` (fast, mechanical/low-risk edits).
- **Effort:** `low` (mechanical), `medium` (standard), `high` (multi-file or subtle logic), `xhigh`/`max` (deep reasoning, high blast radius).

Give the recommendation as a copy-pasteable line, e.g. `→ claude-sonnet-4-6 @ high`.

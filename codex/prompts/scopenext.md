---
description: Summarize the next task and proposed changes, then recommend a model and reasoning effort for the implementation
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

### 3. Recommended model & reasoning effort
Recommend one exact Codex model ID and one `model_reasoning_effort` level for the *implementation* step, with a one-line justification tied to the task's complexity and risk.

- **Model:** choose from the models available to the current Codex installation/account. Prefer the configured default when it fits; recommend a different available model only when the task's difficulty, latency, or cost tradeoff warrants it. Do not invent a model ID or rely on a hard-coded model menu that may become stale.
- **Effort:** `minimal`/`low` (mechanical), `medium` (standard), `high` (multi-file or subtle logic), `xhigh` (deep reasoning, high blast radius).

Give the recommendation as copy-pasteable config lines, e.g.:

```toml
model = "<exact-model-id>"
model_reasoning_effort = "high"
```

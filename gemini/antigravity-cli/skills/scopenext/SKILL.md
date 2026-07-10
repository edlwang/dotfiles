---
name: scopenext
description: Scopes the single next task and recommends a model to implement it. Use when asked what to do next, to scope or size the next step, or to pick a model for the upcoming change — e.g. "scope the next task", "what's next and how hard is it", "which model for the next step".
---

# Scope the next task and recommend a model

## Instructions

Identify the next task from the user's request and the conversation, then scope it and recommend how to implement it:

- **A free-form task description** — scope that task.
- **A plan file or doc** (e.g. `PLAN.md`, a path) — read it and scope the next unstarted step.
- **One or more files/dirs** — read them and scope the change implied for them, asking what outcome is wanted only if it's genuinely ambiguous.
- **Nothing specific given** — infer the next task from the project's own backlog (e.g. `TODO.md`, an open plan doc, or `git status`/recent commits). State explicitly what you inferred and why.

Do **not** start implementing. Produce only the following summary:

### 1. Task
One or two sentences: what is being done and why.

### 2. Proposed changes
A concrete, file-level list of the edits you'd make — paths, functions/sections touched, and the nature of each change. Note anything you'd verify or any open questions that block a clean implementation.

### 3. Recommended model
Recommend one model for the *implementation* step, with a one-line justification tied to the task's complexity and risk.

- **Models:** `Claude Opus 4.6 (Thinking)` (hardest reasoning/architecture), `Claude Sonnet 4.6 (Thinking)` (balanced default), `Gemini 3.5 Flash (High)` (fast, mechanical/low-risk edits).

Give the recommendation as a copy-pasteable line, e.g. `→ Claude Sonnet 4.6 (Thinking)`.

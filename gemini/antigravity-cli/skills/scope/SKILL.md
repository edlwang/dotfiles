---
name: scope
description: Scopes a whole plan, file, or task as one unit and recommends a model to implement it. Use when asked to scope, size, or plan work, or to pick a model before implementing a change — e.g. "scope this plan", "how big is this", "what model should implement PLAN.md".
---

# Scope the whole plan and recommend a model

## Instructions

Identify what to scope from the user's request and the conversation, then scope it *as a whole* and recommend how to implement it:

- **A plan file or doc** (e.g. `PLAN.md`, a path) — read it and scope all of its unstarted work together.
- **One or more files/dirs** — read them and scope the changes implied across them.
- **A free-form task description** — scope it.
- **Nothing specific given** — infer the full backlog from the project's own sources (e.g. `TODO.md`, an open plan doc, or `git status`/recent commits). State explicitly what you inferred and why.

Treat the entire plan/file as a single unit of work — not just the next chunk or step.

Do **not** start implementing. Produce only the following summary:

### 1. Scope
A short paragraph: what the plan accomplishes overall and why.

### 2. Proposed changes
A concrete, file-level list of the edits the plan entails — paths, functions/sections touched, and the nature of each change. Note anything you'd verify or any open questions that block a clean implementation.

### 3. Recommended model
Recommend one model for implementing the *whole plan*, with a one-line justification tied to its overall complexity and risk.

- **Models:** `Claude Opus 4.6 (Thinking)` (hardest reasoning/architecture), `Claude Sonnet 4.6 (Thinking)` (balanced default), `Gemini 3.5 Flash (High)` (fast, mechanical/low-risk edits).

Give the recommendation as a copy-pasteable line, e.g. `→ Claude Sonnet 4.6 (Thinking)`.

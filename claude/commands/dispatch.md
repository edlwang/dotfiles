---
description: Dispatch a subagent to carry out a task, then review its work yourself. Reuses a /scope or /scopenext recommendation when one is present.
argument-hint: [task description | plan/files | (blank = infer from the latest scope output or the backlog)]
---

## Task

$ARGUMENTS

## Instructions

Delegate the work described (or implied) by **Task** above to a subagent, then
independently verify the result. The task is arbitrary — anything you'd otherwise
do yourself; this skill just splits it into *dispatch* and *check* so the work
gets a second set of eyes. It also picks up cleanly after `/scope` or `/scopenext`
when one has already sized the work.

### 1. Settle the task and the model
- Take the task from **Task** above. Blank = infer it from the latest `/scope` or
  `/scopenext` summary in the conversation, or failing that the project's backlog
  (an open plan doc, `TODO.md`, `git status`/recent commits).
- Pick the model & effort to dispatch at: if a `/scope`/`/scopenext` summary
  already recommended one, use it; otherwise choose one to fit the task's
  complexity and risk.

State in one line what you're dispatching and at what model/effort, then proceed
unless the task is genuinely ambiguous.

### 2. Dispatch an implementation agent
Launch a subagent (Task/Agent tool) at that model — and effort, where the harness
supports it — to do the work. Hand it the concrete goal, the relevant paths, and
the repo's conventions (`AGENTS.md`/`CLAUDE.md`). Also tell it explicitly which
model it's running as (the model you dispatched it at) so any commit attribution it
writes names that model instead of guessing. Prefer one focused subagent per
coherent unit of work; run independent units in parallel.

### 3. Check its work
Once it returns, review the result **yourself** against the goal from step 1. You
didn't write the code — the subagent did — so you already bring the independent
eyes the check needs; don't spawn a separate reviewer for it. Confirm it does what
was asked, follows repo conventions, and is actually verified (built/ran/tests pass
— not just asserted). Fix, or dispatch a fix for, anything you surface.

Report back: what landed, how it was verified, and anything still open.

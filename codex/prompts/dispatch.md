---
description: Delegate a task, then check the result with a fresh review pass. Reuses a /scope or /scopenext recommendation when one is present.
argument-hint: [task description | plan/files | (blank = infer from the latest scope output or the backlog)]
---

## Task

$ARGUMENTS

## Instructions

Carry out the work described (or implied) by **Task** above, then independently
verify the result. The task is arbitrary — anything you'd otherwise do yourself;
this skill just splits it into *do* and *check* so the work gets a second set of
eyes. It also picks up cleanly after `/scope` or `/scopenext` when one has already
sized the work.

### 1. Settle the task, model, and effort
- Take the task from **Task** above. Blank = infer it from the latest `/scope` or
  `/scopenext` summary in the conversation, or failing that the project's backlog
  (an open plan doc, `TODO.md`, `git status`/recent commits).
- Pick the model and effort: if a `/scope`/`/scopenext` summary already recommended
  them, use both; otherwise choose an available model and
  `model_reasoning_effort` to fit the task's complexity, risk, latency, and cost.

State in one line what you're doing, with which model, and at what effort; select
that model and set `model_reasoning_effort` to match, then proceed unless the task
is genuinely ambiguous.

### 2. Do the work
Delegate to a subagent if your harness can spawn one; otherwise carry the work out
yourself at the chosen effort. When you delegate, tell the subagent explicitly which
model it's running as (the model you dispatched it at) so any commit attribution it
writes names that model instead of guessing. Work to the repo's conventions
(`AGENTS.md`); keep each logical unit of work a focused commit.

### 3. Check the work
Give the result a **distinct** review pass yourself. If you delegated, you didn't
write the work — so you already bring the fresh eyes the check needs; review the
returned result directly rather than spawning a separate reviewer. If you did the
work yourself, re-read the diff as a critic, not the author. Confirm it does what
was asked, follows repo conventions, and is actually verified (built/ran/tests pass
— not just asserted). Fix anything the review surfaces.

Report back: what landed, how it was verified, and anything still open.

---
name: dispatch
description: Delegates a task to a subagent (or carries it out) and then checks the result with a fresh review pass. Use when asked to hand a task off and verify it, e.g. "dispatch this and check the work", "go do this then review it", "spin up an agent for this task". Picks up cleanly after the scope or scopenext skills.
---

# Dispatch a task and check the work

## Instructions

Carry out the work the user wants done, then independently verify the result. The
task is arbitrary — anything you'd otherwise do yourself; this skill just splits it
into *do* and *check* so the work gets a second set of eyes. It also picks up
cleanly after the `scope` and `scopenext` skills when one has already sized the
work.

### 1. Settle the task
Identify the task from the user's request and the conversation:

- If a `scope`/`scopenext` summary is already in the conversation, reuse its goal
  and recommended model.
- Nothing specific given = infer the task from the project's backlog (an open plan
  doc, `TODO.md`, or `git status`/recent commits).

State in one line what you're doing, then proceed unless it's genuinely ambiguous.

### 2. Do the work
Delegate to a subagent if your harness can spawn one; otherwise carry the work out
yourself. When you delegate, tell the subagent explicitly which model it's running
as (the model you dispatched it at) so any commit attribution it writes names that
model instead of guessing. Work to the repo's conventions (`AGENTS.md`); keep each
logical unit of work focused.

### 3. Check the work
Give the result a **distinct** review pass yourself. If you delegated, you didn't
write the work — so you already bring the fresh eyes the check needs; review the
returned result directly rather than spawning a separate reviewer. If you did the
work yourself, re-read the diff as a critic, not the author. Confirm it does what
was asked, follows the repo's conventions, and is actually verified (built/ran/tests
pass — not just asserted). Fix anything the review surfaces.

Report back: what landed, how it was verified, and anything still open.

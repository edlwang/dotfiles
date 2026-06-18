# Global instructions for Claude Code

Personal, cross-project preferences for every session. A repo's own
`CLAUDE.md` / `AGENTS.md` is more specific and overrides this file.

## Working preferences

- Never push to a remote (`git push`); leave pushing to me.
- Commit automatically after each logical unit of work, without waiting to be asked;
  group related changes into focused commits with clear messages.
- Write commit messages in Conventional Commits format: `type(scope): summary`
  (`feat`, `fix`, `docs`, `refactor`, `chore`, `test`, `build`, `ci`). Pick the type
  by the change's intent, not the file touched; scope is optional.
- After completing a task or answering a question, summarize each command ran
  and explain the rationale.
- Don't claim a change works unless you verified it (ran it, or tests pass). If you
  didn't verify, say so plainly.

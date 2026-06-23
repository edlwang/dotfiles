# Global instructions for Claude Code

Personal, cross-project preferences for every session. A repo's own
`CLAUDE.md` / `AGENTS.md` is more specific and overrides this file.

## Working preferences

- When writing or refactoring code, prioritize correctness, then elegance and
  readability, and performance last.
- Don't claim a change works unless you verified it (ran it, or tests pass). If you
  didn't verify, say so plainly.
- If you don't have access to modify or run certain tools, give me the command to
  run it.

### Git

- Never push to a remote (`git push`); leave pushing to me.
- Commit automatically after each logical unit of work, without waiting to be asked;
  group related changes into focused commits with clear messages.
- Write commit messages in Conventional Commits format: `type(scope): summary`
  (`feat`, `fix`, `docs`, `refactor`, `chore`, `test`, `build`, `ci`). Pick the type
  by the change's intent, not the file touched; scope is optional.
- When writing commits, make sure to perform a diff to ensure that the commit message
  only references details captured in the repository and not any intermediate changes
  done locally
- Always include AI attribution in commit messages
- Whenever you are asked to merge, always use --no-ff

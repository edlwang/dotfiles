# AGENTS.md

Guidance for AI coding agents working in this repository.

**[README.md](README.md) is the source of truth** for what this project is, how
to install it, its dependencies, and the full architecture (Neovim, WezTerm,
shell, and Claude Code config). Read it first — this file only adds the working
rules and gotchas an agent needs on top of that documentation.

## How to work here

- **No build or test step.** The "product" is configuration; `init.sh` symlinks
  tracked files into `$HOME`, so editing a file here changes the live config
  immediately. Verify a change by sourcing it (`source ~/.bashrc`) or relaunching
  the affected app (Neovim, WezTerm) — there is no suite to run. Don't claim
  something works unless you've checked it that way.
- **Keep `bashrc`/`bash_aliases` cross-platform.** OS-specific shell code belongs
  in the per-platform `bashrc_<os>` files, and OS-specific *setup* logic in
  `init_<os>.sh` (see README → Shell).
- **Commits:** one focused commit per logical unit, in Conventional Commits
  format (`type(scope): summary`). Diff your changes before committing so the
  message reflects only what landed in the repo. Never `git push` — leave that to
  the user.

## Conventions to preserve

These are easy to get wrong; the README explains each in full.

- **Neovim keymaps** are centralized in `editor/keybinds.lua` and follow the
  `[bracketed]`-letter `desc` + lazy-`require`-in-callback convention, with a few
  documented exceptions that live with their plugin. New leader groups also need
  a label in `plugins/whichkey.lua`. See README → Keybinding convention.
- **WezTerm split names are intentionally inverted** vs. Terminator/tmux — don't
  "correct" them. Add leader symbol binds through the `leader_symbol()` helper,
  not as plain `config.keys` entries. See README → WezTerm.
- **Global agent instructions are one shared file.** The working preferences
  every agent reads live in `shared/agent-instructions.md`; `init.sh` symlinks it
  into each home as the name that tool expects (`~/.claude/CLAUDE.md`,
  `~/.codex/AGENTS.md`, `~/.gemini/GEMINI.md`). Edit preferences there — don't
  re-fork per-tool copies. Keep it byte-identical-friendly: no tool-specific
  wording, since all three consume the same text. See README → Shared agent
  instructions.
- **Adding a new *kind* of Claude or Antigravity config** under `claude/` or
  `gemini/antigravity-cli/` is a two-step: drop the file, then whitelist it in
  `.gitignore` (`!claude/<name>` / `!gemini/antigravity-cli/<name>`, plus
  `!claude/<name>/**` / `!gemini/antigravity-cli/<name>/**` for a directory) or git
  silently ignores it. See README → Claude Code config and README → Antigravity
  config.
- **The `scope`/`scopenext`/`dispatch` prompts are per-tool copies — mirror
  edits across all three.** Each lives as a Claude command (`claude/commands/`),
  a Codex prompt (`codex/prompts/`), and an Antigravity skill
  (`gemini/antigravity-cli/skills/`). They stay separate because frontmatter and
  templating genuinely differ (`$ARGUMENTS` vs description-triggered), so a
  change to one's guidance should be applied to the other two. One exception:
  the model menus diverge on purpose — Claude/Codex name the API lineup
  (`claude-opus-4-8`, `claude-sonnet-5`, …) while the Antigravity skills track
  Antigravity's own, lagging Claude selector; don't "sync" one to the other.
- **Antigravity skills are description-triggered, not slash commands.** The CLI
  semantic-matches against `description` — no `$ARGUMENTS` substitution; the
  skill derives its target from the request. See README → Antigravity config.


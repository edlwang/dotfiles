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
  `~/.codex/AGENTS.md`, `~/.gemini/antigravity-cli/AGENTS.md`). Edit preferences
  there — don't re-fork per-tool copies. Keep it byte-identical-friendly: no
  tool-specific wording, since all three consume the same text. See README →
  Shared agent instructions.
- **Adding a new *kind* of Claude config** under `claude/` is a two-step: drop
  the file, then whitelist it in `.gitignore` (`!claude/<name>`, plus
  `!claude/<name>/**` for a directory) or git silently ignores it. See README →
  Claude Code config.

# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## What this is

Personal dotfiles for bash + Neovim. There is no build or test step — the "product" is configuration. `init.sh` symlinks tracked files from this repo into `$HOME`, so **editing a file here immediately changes the live config** (the symlink targets point back into this repo). The Neovim config is the bulk of the repository.

## Setup & common commands

- `bash init.sh` — idempotent installer: symlinks dotfiles into `$HOME` (backing up any pre-existing real files to `~/dotfiles_backup_<timestamp>/`), installs `starship` and `uv` if missing, and creates a `~/py313` uv venv. Safe to re-run.
- `source ~/.bashrc` (alias `sbrc`) — apply shell changes after editing `bashrc`/`bash_aliases`. Neovim changes take effect on next launch.
- External deps required for the Neovim plugins: **NPM** (Mason uses it to install some LSP servers) and **tree-sitter-cli** (treesitter parser builds).

Inside Neovim:
- `:Lazy` — plugin manager UI (install/update/sync). `nvim/lazy-lock.json` is the committed lockfile; commit it when plugin versions change.
- `:Mason` — manage LSP servers / tools. They auto-install from the declarations in `plugins/lsp-config.lua`.
- `:TSUpdate` — update treesitter parsers.
- Lua is formatted by **stylua** (no config file → stylua defaults: tabs). conform runs it on save; `<leader>cf` formats manually.

## Neovim architecture (`nvim/`)

Entry: `init.lua` → `require("edlwang")`. Everything lives under the personal namespace `lua/edlwang/`:

- `edlwang/init.lua` sets the leader (`<Space>`, single source of truth) before loading `edlwang.editor` (built-in settings) then `edlwang.lazy` (plugins).
- `edlwang/lazy.lua` bootstraps **lazy.nvim** and auto-imports every file in `plugins/` via `{ import = "edlwang.plugins" }`.
- `editor/` — one concern per file (`spacing`, `search`, `linenumbers`, `windows`, `undo`, `terminal`, `misc`, `keybinds`), each registered in `editor/init.lua`. To add a settings module, create the file and add a `require` line there.
- `plugins/` — one plugin per file, each **returning a lazy.nvim spec table**. Just dropping a new `plugins/<name>.lua` that returns a spec is enough to register it; no central list to edit.

### Keybinding convention (important)

Nearly all keymaps are centralized in `editor/keybinds.lua`, not scattered across plugin files. Two rules the existing code follows:

1. **`[bracketed]` letters in every `desc`** encode the keys pressed (e.g. `"[C]ode [R]ename"` → `<leader>cr`). These surface in which-key.
2. Plugin keymaps in `keybinds.lua` `require()` their plugin **lazily inside the callback** so the file can load before plugins and lazy-loading still triggers on first press.

Deliberate exceptions (documented in `keybinds.lua`'s header comment) that live with their plugin instead:
- LSP maps (`gd`, `gr`, `gy`, `<leader>cr`, `<leader>ca`, `K`, …) are **buffer-local**, set on `LspAttach` in `plugins/lsp-config.lua`.
- nvim-cmp completion-menu maps (`<C-n>`, `<C-y>`, …) are internal to cmp in `plugins/cmp.lua`.
- toggleterm's open mapping (`<leader>tt`) is the plugin's `open_mapping` option.

When adding a leader-prefixed group, also add its label to the `spec` in `plugins/whichkey.lua` so which-key shows the group name.

### LSP / completion / formatting stack

`plugins/lsp-config.lua` wires **mason + mason-lspconfig + mason-tool-installer**. To enable a language server, add a key to the `servers` table (e.g. `gopls = {}`); it's then auto-installed and configured, with capabilities merged from nvim-cmp. Per-server overrides (settings/cmd/filetypes) go in that table's value. Add non-LSP tools (formatters, etc.) to the `ensure_installed` list. Completion is nvim-cmp (`plugins/cmp.lua`); autoformat is conform (`plugins/conform.lua`, add filetypes under `formatters_by_ft`). Colorscheme is `tokyonight-moon`.

## Shell config (`bashrc`, `bash_aliases`)

- `SYSTEM_OS` is derived from `uname` and gates OS-specific behavior (e.g. the `ls` alias).
- `cd` is overridden to use `pushd` (a directory stack); `vdirs` (`dirs -v`) lists it.
- `pyenv` alias activates the `~/py313` uv venv created by `init.sh`.
- `gitconfig` rewrites `https://github.com/` push URLs to SSH (`git@github.com:`).

## Claude Code config (`claude/`)

Default Claude Code config lives in `claude/` (e.g. `settings.json`). `init.sh`'s `setup_claude` step symlinks **each top-level entry** of `claude/` into `~/.claude/` — it globs the directory, so nothing to edit on the symlink side — and leaves the rest of `~/.claude/` (credentials, history, sessions, jobs — all runtime state) untouched. Because everything in `claude/` is symlinked, **only put config files here**, never runtime state or secrets.

**Git tracking uses a whitelist, decoupled from that glob.** `.gitignore` ignores all of `claude/` and re-includes only `CLAUDE.md`, `settings.json`, `commands/`, and `agents/` — a fail-safe so credentials or runtime state can never be committed even if copied in. The catch: `setup_claude` will symlink *anything* you drop in `claude/`, but git **silently ignores** a new config type (e.g. `output-styles/`, a `statusline.sh`) until you add a matching `!claude/<name>` line — plus `!claude/<name>/**` for a directory — to `.gitignore`. So adding a new *kind* of config is a two-step: drop the file, then whitelist it.

`setup_claude` symlinks each **top-level** entry, so a subdirectory like `claude/commands/` becomes a whole-directory symlink (`~/.claude/commands` → repo). If a real `~/.claude/commands/` already exists, `setup_symlink` moves it to the backup dir and replaces it with the link — so only track directories whose contents you fully own in the repo, not ones Claude or plugins also write to at runtime.

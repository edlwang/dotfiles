# dotfiles

Personal dotfiles for bash, Neovim, and WezTerm. `init.sh` symlinks the tracked
files into `$HOME`, so editing a file in this repo immediately changes the live
config. See [AGENTS.md](AGENTS.md) for the architecture.

## Quickstart

```bash
git clone https://www.github.com/edlwang/dotfiles.git "$HOME/dotfiles/"
bash "$HOME/dotfiles/init.sh"
source ~/.bashrc   # or open a new shell
```

`init.sh` is idempotent — safe to re-run. It backs up any pre-existing real
files to `~/dotfiles_backup_<timestamp>/` before symlinking.

## Dependencies

Derived by reading the configs, not by provisioning a clean machine — treat it
as the known set, not a guarantee.

### Installed by `init.sh`

- **starship** and **uv** — via `curl | sh` on Linux/macOS, via winget/scoop on
  Windows.
- **`~/py313`** — a Python 3.13 venv created by uv; the `pyenv` alias activates it.

### Install yourself

`init.sh` symlinks the configs but does **not** install these. Nothing checks for
them, so a missing one fails quietly or only when you hit the feature.

- **Neovim ≥ 0.11** — the config uses the `vim.lsp.config` API introduced in 0.11.
- **Node.js + npm** — Mason installs several LSP servers as npm packages
  (`pyright`, `jsonls`, `html`); markdown-preview builds via `npx yarn`.
- **tree-sitter CLI** — treesitter parser builds (incl. the LaTeX parser).
- **ripgrep (`rg`)** — Telescope `live_grep` / `grep_string`.
- **fd** *(optional)* — speeds up Telescope `find_files`; on Debian/Ubuntu the
  binary is `fdfind`.
- **C compiler (`gcc`/`clang`/`cc`) + `make`** — nvim-treesitter compiles parsers
  from C, and `telescope-fzf-native.nvim` builds with `make`.
- **WezTerm** + **FiraMono Nerd Font** — the terminal and the font that renders
  Neovim's icons (neo-tree, lualine, which-key, fidget).
- **TeX distribution + PDF viewer** *(optional)* — only for LaTeX via VimTeX /
  the `texlab` LSP.
- **Windows only:** **Git for Windows** (provides the bash that runs `init.sh`,
  and WezTerm launches `C:/Program Files/Git/bin/bash.exe` as its shell — it must
  be at that path); **winget or scoop**; **Developer Mode** on, or an elevated
  shell, so `init.sh` can create real symlinks.

### Handled inside Neovim

On first launch, **Mason** auto-installs the LSP servers (`pyright`, `jsonls`,
`html`, `lua_ls`, `rust_analyzer`, `texlab`) and `stylua` declared in
`plugins/lsp-config.lua`. `rust_analyzer` / `texlab` arrive as standalone
binaries but need a Rust toolchain / TeX install to be useful.

> **Planned:** extend `init.sh` to auto-install Node, the tree-sitter CLI,
> ripgrep, and fd so the manual list above shrinks to a minimal bootstrap. See
> [init-tooling-plan.md](init-tooling-plan.md).

## Optional per-machine git identity

`gitconfig` ends with `[include] path = ~/.gitconfig.local`. Create that
untracked file to override the committed name/email on a given machine.

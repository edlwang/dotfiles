# dotfiles

Personal dotfiles for bash, Neovim, and WezTerm. `init.sh` symlinks the tracked
files in this repo into `$HOME`, so **editing a file here immediately changes the
live config** (the symlinks point back into this repo). There is no build or test
step — the "product" is the configuration itself. The Neovim config is the bulk
of the repository.

## Quickstart

```bash
git clone https://www.github.com/edlwang/dotfiles.git "$HOME/dotfiles/"
bash "$HOME/dotfiles/init.sh"
source ~/.bashrc   # or open a new shell
```

`init.sh` is idempotent — safe to re-run. It backs up any pre-existing real files
to `~/dotfiles_backup_<timestamp>/` before symlinking, installs `starship` and
`uv` if missing, and creates a `~/py313` uv venv. On Windows it enables real
symlinks (`MSYS=winsymlinks:nativestrict`, which needs Developer Mode or an
elevated shell) and installs tools via `winget`/`scoop` instead of the
`curl | sh` scripts.

Apply later edits with `source ~/.bashrc` (alias `sbrc`) for `bashrc`/
`bash_aliases` changes. Neovim changes take effect on next launch; WezTerm
auto-reloads its config on save.

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

## Architecture

### Neovim (`nvim/`)

Entry: `init.lua` → `require("edlwang")`. Everything lives under the personal
namespace `lua/edlwang/`:

- `edlwang/init.lua` sets the leader (`<Space>`, single source of truth) before
  loading `edlwang.editor` (built-in settings) then `edlwang.lazy` (plugins).
- `edlwang/lazy.lua` bootstraps **lazy.nvim** and auto-imports every file in
  `plugins/` via `{ import = "edlwang.plugins" }`.
- `editor/` — one concern per file (`spacing`, `search`, `linenumbers`,
  `windows`, `undo`, `terminal`, `misc`, `diagnostics`, `providers`,
  `keybinds`), each registered in `editor/init.lua`. To add a settings module,
  create the file and add a `require` line there.
- `plugins/` — one plugin per file, each **returning a lazy.nvim spec table**.
  Just dropping a new `plugins/<name>.lua` that returns a spec is enough to
  register it; no central list to edit.

Plugins and tools are managed from inside Neovim:

- `:Lazy` — plugin manager UI (install/update/sync). `nvim/lazy-lock.json` is the
  committed lockfile; commit it when plugin versions change.
- `:Mason` — manage LSP servers / tools. They auto-install from the declarations
  in `plugins/lsp-config.lua`.
- `:TSUpdate` — update treesitter parsers.
- Lua is formatted by **stylua** (no config file → stylua defaults: tabs).
  conform runs it on save; `<leader>cf` formats manually.

#### Keybinding convention

Nearly all keymaps are centralized in `editor/keybinds.lua`, not scattered across
plugin files. Two rules the existing code follows:

1. **`[bracketed]` letters in every `desc`** encode the keys pressed (e.g.
   `"[C]ode [R]ename"` → `<leader>cr`). These surface in which-key.
2. Plugin keymaps in `keybinds.lua` `require()` their plugin **lazily inside the
   callback** so the file can load before plugins and lazy-loading still triggers
   on first press.

Deliberate exceptions (documented in `keybinds.lua`'s header comment) live with
their plugin instead:

- LSP maps (`gd`, `gr`, `gy`, `<leader>cr`, `<leader>ca`, `K`, …) are
  **buffer-local**, set on `LspAttach` in `plugins/lsp-config.lua`.
- nvim-cmp completion-menu maps (`<C-n>`, `<C-y>`, …) are internal to cmp in
  `plugins/cmp.lua`.
- toggleterm's open mapping (`<leader>tt`) is the plugin's `open_mapping` option.

When adding a leader-prefixed group, also add its label to the `spec` in
`plugins/whichkey.lua` so which-key shows the group name.

#### LSP / completion / formatting stack

`plugins/lsp-config.lua` wires **mason + mason-lspconfig + mason-tool-installer**.
To enable a language server, add a key to the `servers` table (e.g. `gopls = {}`);
it's then auto-installed and configured, with capabilities merged from nvim-cmp.
Per-server overrides (settings/cmd/filetypes) go in that table's value. Add
non-LSP tools (formatters, etc.) to the `ensure_installed` list. Completion is
nvim-cmp (`plugins/cmp.lua`); autoformat is conform (`plugins/conform.lua`, add
filetypes under `formatters_by_ft`). Colorscheme is `tokyonight-moon`.

### WezTerm (`wezterm/`)

One file: `wezterm/wezterm.lua`, returning a table built with
`wezterm.config_builder()`; WezTerm auto-reloads it on save. A few things shape
how it's structured:

- **Two keybinding layers, both feeding `config.keys`.** Terminator-style
  *direct* binds (`Ctrl+Shift+…`, `Alt+hjkl`) are set straight on `config.keys`;
  a **tmux-style command layer** behind a leader prefix (`config.leader` =
  `Ctrl+Space`) is assembled in the `tmux_keys` table and appended at the bottom.
  The prefix is `Ctrl+Space` deliberately so it never collides with tmux's
  `Ctrl+b` — a real tmux can run inside a WezTerm pane (locally or over SSH) with
  both layers live at once.
- **Split names are inverted vs. Terminator/tmux.** Those call the *below* split
  "horizontal"; WezTerm calls it `SplitVertical` (and the *right* split
  `SplitHorizontal`). The binds map Terminator's `Ctrl+Shift+O` and tmux's `"` to
  `SplitVertical`, etc. — matching muscle memory, not the names. Don't "correct"
  the apparent mismatch.
- **Leader symbol keys (`%` `"` `&` `:` `[` `]` `,`) go through the
  `leader_symbol()` helper.** A bare `{ key = "%" }` matches by physical key
  position and silently fails for shifted symbols; the helper binds by produced
  character (with `mapped:`, and both with and without `SHIFT`, since WezTerm
  versions disagree on whether the shift is reported). Add new symbol binds
  through it, not as plain `{ key = …, mods = L }` entries.
- **Multiplexing + persistence are always on:** `config.unix_domains` plus
  `default_gui_startup_args = { "connect", "unix" }` run panes/tabs in a
  background mux server that reattaches on next launch — the `tmux
  detach`/`attach` equivalent (survives closing the window, not a reboot).
  `default_gui_startup_args` only applies when `wezterm-gui` is launched with
  **no subcommand**: on Windows the `default_prog`/shortcut flow does exactly
  that, but Linux's distro `.desktop` entry hardcodes `Exec=wezterm start --cwd
  .`, whose explicit `start` overrides it and opens non-persistent local-domain
  windows. So `init.sh`'s `setup_os` (in `init_linux.sh`) installs a user-level
  `org.wezfurlong.wezterm.desktop` (tracked at
  `wezterm/org.wezfurlong.wezterm.desktop`) that shadows the system one and
  launches `wezterm-gui connect unix`. It assumes a native install (binary on
  `PATH`); Flatpak/Snap would need a different `Exec`.
- **The `.desktop` override only fixes the applications-list launcher — not
  `Ctrl+Alt+T`.** That chord is GNOME's `media-keys` *terminal* action, which
  launches `x-terminal-emulator` (on Ubuntu, `update-alternatives`'d to the
  wezterm package's `open-wezterm-here`, i.e. `wezterm start --cwd …`) rather
  than the `.desktop` entry, so it hits the same non-persistent `start` path.
  `setup_os`'s `bind_terminal_shortcut` takes the shortcut over at the user
  level: a GNOME custom keybinding (`gsettings`, relocatable schema path
  `…/custom-keybindings/wezterm-mux/`) bound to `<Primary><Alt>t` → `wezterm-gui
  connect unix`, plus unbinding the built-in `terminal` key so the chord doesn't
  double-fire. This is **the one place init writes live user settings (dconf)
  instead of symlinking a tracked file**, so it's not reverted by removing a
  symlink. It's GNOME-gated (skips silently when the `media-keys` schema is
  absent — other DEs would each need their own mechanism), idempotent, root-free,
  and the `terminal` unbind is guarded for GNOME builds that lack that key.

The config-dir symlinking and the Windows-only login-shell `default_prog` are
driven by `init.sh`/`os_env` and documented under [Shell](#shell-bashrc-bash_aliases)
below. `wezterm/tmux-testing.md` is a manual test checklist for the command
layer.

### Shell (`bashrc`, `bash_aliases`)

- **OS detection has a single source of truth: `os_env`** (symlinked to
  `~/.os_env`). It sets `SYSTEM_OS` (`Linux`/`macOS`/`Windows`/`Unknown`) and is
  sourced by both `bashrc` (at shell startup) and `init.sh` (at install time,
  from the repo copy since the symlink may not exist on a first run) so they
  never disagree. Keep it side-effect-free apart from setting `SYSTEM_OS`.
- **OS-specific code lives in per-platform files**, not inline in `bashrc`.
  `bashrc` sources `~/.bashrc_linux` / `~/.bashrc_macos` / `~/.bashrc_windows` in
  a `case "$SYSTEM_OS"` block (early, before the interactive guard, so e.g. the
  Windows `HOME` normalization always runs). To add OS-only behavior, edit the
  matching `bashrc_<os>` file — keep `bashrc`/`bash_aliases` cross-platform. New
  platform files must also be added to `init.sh`'s `setup_dotfiles` to be
  symlinked.
- **`bash_profile` just sources `~/.bashrc`** (symlinked to `~/.bash_profile`) so
  *login* shells load the same interactive config as non-login ones — notably the
  `bash -l` WezTerm launches on Windows and the login shell macOS terminals use
  by default.
- **Neovim's config dir is platform-specific.** `init.sh`'s `nvim_config_dir`
  (branching on `SYSTEM_OS`) symlinks the repo's `nvim/` to `$XDG_CONFIG_HOME/nvim`
  if set, else `~/AppData/Local/nvim` on Windows or `~/.config/nvim` elsewhere —
  matching where Neovim actually looks.
- **WezTerm's config dir is `~/.config/wezterm` on every platform.** `init.sh`'s
  `wezterm_config_dir` symlinks the repo's `wezterm/` to `$XDG_CONFIG_HOME/wezterm`
  if set, else `~/.config/wezterm` — WezTerm, unlike Neovim, does *not* use
  AppData on Windows, so there's no Windows branch. On Windows, `wezterm.lua`
  sets `default_prog` to launch Git Bash as a **login** shell (`bash.exe -l -i`);
  without `-l`, MSYS's `/etc/profile` never runs and `/usr/bin` (so `uname`, which
  `os_env` calls at startup) is missing from `PATH`.
- **`init.sh`'s OS-specific *install* logic lives in per-OS files**
  (`init_<os>.sh`, e.g. `init_windows.sh`), sourced by `init.sh` from the repo
  copy (not symlinked into `$HOME` — they're install-time only, unlike
  `bashrc_<os>`). `init.sh` defines defaults — the Unix `install_tools` and a
  no-op `setup_os` hook — and a present `init_<os>.sh` overrides them (and can set
  env like `MSYS`): `init_windows.sh` overrides `install_tools` to use
  winget/scoop; `init_linux.sh` overrides `setup_os` to install the WezTerm
  desktop entry. The sourcing happens after the default definitions but before the
  steps run. Small per-OS *values* (the nvim dir, pyenv path) stay as inline
  `SYSTEM_OS` branches in `init.sh`; only divergent *procedures* move to
  `init_<os>.sh`.
- `cd` is overridden to use `pushd` (a directory stack); `vdirs` (`dirs -v`)
  lists it.
- `pyenv` alias activates the `~/py313` uv venv created by `init.sh`. It's
  OS-gated (lives in the `bashrc_<os>` files, not `bash_aliases`, since those are
  sourced after the platform files): `bin/activate` on Unix, `Scripts/activate`
  on Windows. `setup_pyenv` resolves the same path via `SYSTEM_OS`.
- `gitconfig` rewrites `https://github.com/` push URLs to SSH
  (`git@github.com:`).

### Claude Code config (`claude/`)

Default Claude Code config lives in `claude/` (e.g. `settings.json`). `init.sh`'s
`setup_claude` step symlinks **each top-level entry** of `claude/` into
`~/.claude/` — it globs the directory, so nothing to edit on the symlink side —
and leaves the rest of `~/.claude/` (credentials, history, sessions, jobs — all
runtime state) untouched. Because everything in `claude/` is symlinked, **only
put config files here**, never runtime state or secrets.

**Git tracking uses a whitelist, decoupled from that glob.** `.gitignore` ignores
all of `claude/` and re-includes only `CLAUDE.md`, `settings.json`, `commands/`,
and `agents/` — a fail-safe so credentials or runtime state can never be
committed even if copied in. The catch: `setup_claude` will symlink *anything*
you drop in `claude/`, but git **silently ignores** a new config type (e.g.
`output-styles/`, a `statusline.sh`) until you add a matching `!claude/<name>`
line — plus `!claude/<name>/**` for a directory — to `.gitignore`. So adding a
new *kind* of config is a two-step: drop the file, then whitelist it.

`setup_claude` symlinks each **top-level** entry, so a subdirectory like
`claude/commands/` becomes a whole-directory symlink (`~/.claude/commands` →
repo). If a real `~/.claude/commands/` already exists, `setup_symlink` moves it
to the backup dir and replaces it with the link — so only track directories whose
contents you fully own in the repo, not ones Claude or plugins also write to at
runtime.

## Optional per-machine git identity

`gitconfig` ends with `[include] path = ~/.gitconfig.local`. Create that
untracked file to override the committed name/email on a given machine.

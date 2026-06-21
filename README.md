# dotfiles

> Runs on **Linux**, **macOS**, and **Windows** (via Git Bash).

Personal dotfiles for bash, Neovim, and WezTerm. `init.sh` symlinks the tracked
files in this repo into `$HOME`, so **editing a file here immediately changes the
live config** (the symlinks point back into this repo). There is no build or test
step — the "product" is the configuration itself. The Neovim config is the bulk
of the repository.

## Contents

- [Quickstart](#quickstart)
- [Repository layout](#repository-layout)
- [Common tasks](#common-tasks)
- [Dependencies](#dependencies)
- [Architecture](#architecture) — [Neovim](#neovim-nvim) · [WezTerm](#wezterm-wezterm) · [Shell](#shell-bashrc-bash_aliases) · [Claude Code](#claude-code-config-claude)
- [Optional per-machine git identity](#optional-per-machine-git-identity)

## Quickstart

```bash
git clone https://www.github.com/edlwang/dotfiles.git "$HOME/dotfiles/"
bash "$HOME/dotfiles/init.sh"
source ~/.bashrc   # or open a new shell
```

`init.sh` is idempotent — safe to re-run. It backs up any pre-existing real files
to `~/dotfiles_backup_<timestamp>/`, symlinks the configs into place, and (if `uv`
is installed) creates a `~/py313` uv venv. It is **config-only**: it installs no
tools — provision those yourself (see [Install yourself](#install-yourself)). On
Windows it also enables real symlinks (`MSYS=winsymlinks:nativestrict`, which
needs Developer Mode or an elevated shell).

Apply later edits with `source ~/.bashrc` (alias `sbrc`) for `bashrc`/
`bash_aliases` changes. Neovim changes take effect on next launch; WezTerm
auto-reloads its config on save.

## Repository layout

```text
.
├── init.sh             Idempotent setup: symlinks dotfiles (config-only)
├── init_linux.sh       Linux setup hook (WezTerm .desktop + Ctrl+Alt+T shortcut)
├── init_windows.sh     Windows setup hook (enables real symlinks)
├── shellenv            Sets $SYSTEM_OS + shared shell helpers; sourced by bashrc + init.sh
├── bashrc              Cross-platform shell config (the entry point)
├── bash_aliases        Cross-platform aliases
├── bash_profile        Sources ~/.bashrc so login shells match interactive ones
├── bashrc_linux        }
├── bashrc_macos        }  Per-OS shell config, sourced by bashrc
├── bashrc_windows      }
├── gitconfig           Git config (rewrites GitHub https push URLs to ssh)
├── nvim/               Neovim config — the bulk of the repo
│   ├── init.lua            → require("edlwang")
│   ├── lazy-lock.json      Plugin lockfile (commit when versions change)
│   └── lua/edlwang/        editor/ (built-in settings) + plugins/ (one per plugin)
├── wezterm/
│   ├── wezterm.lua                     The entire WezTerm config
│   ├── org.wezfurlong.wezterm.desktop  Linux launcher override (persistent mux)
│   └── tmux-testing.md                 Manual test checklist for the command layer
├── claude/             Claude Code config → symlinked into ~/.claude
│   ├── settings.json
│   └── CLAUDE.md
├── AGENTS.md           Working rules for AI coding agents (points back here)
├── CLAUDE.md           Sources AGENTS.md for Claude Code
└── README.md           You are here
```

## Common tasks

Quick map of "I want to change X" → where to do it. See
[Architecture](#architecture) for the *why* behind each.

| Goal | Where |
| --- | --- |
| Apply shell edits | `source ~/.bashrc` (alias `sbrc`) |
| Add a shell alias | edit `bash_aliases`, then `sbrc` |
| Add OS-specific shell behavior | edit `bashrc_<os>` (keep `bashrc`/`bash_aliases` cross-platform) |
| Add a Neovim plugin | drop `nvim/lua/edlwang/plugins/<name>.lua` returning a lazy.nvim spec |
| Add a Neovim settings module | create `editor/<name>.lua` + add a `require` in `editor/init.lua` |
| Enable/configure an LSP server | add a key to the `servers` table in `plugins/lsp-config.lua` |
| Add a formatter | `ensure_installed` in `plugins/lsp-config.lua` + `formatters_by_ft` in `plugins/conform.lua` |
| Add/change a keybinding | `editor/keybinds.lua` (follow the `[bracketed]`-`desc` rule; new groups → `plugins/whichkey.lua`) |
| Change the colorscheme | `plugins/themes.lua` (currently `tokyonight-moon`) |
| Update plugins | `:Lazy` in Neovim, then commit `nvim/lazy-lock.json` |
| Update treesitter parsers | `:TSUpdate` in Neovim |
| Per-machine git name/email | create `~/.gitconfig.local` (see below) |

## Dependencies

Derived by reading the configs, not by provisioning a clean machine — treat it
as the known set, not a guarantee.

### Install yourself

`init.sh` is **config-only**: it symlinks the configs and, if `uv` is already
present, creates the `~/py313` venv — but it installs **no** tools. Nothing checks
for them, so a missing one fails quietly or only when you hit the feature.

Provision per OS:

- **macOS** — Homebrew:

  ```bash
  brew install starship uv node ripgrep fd tree-sitter neovim
  brew install --cask wezterm font-fira-mono-nerd-font
  ```

- **Windows** — `winget` for most, `scoop` for the two with no winget package:

  ```bash
  winget install Starship.Starship astral-sh.uv OpenJS.NodeJS \
      BurntSushi.ripgrep.MSVC sharkdp.fd Neovim.Neovim wez.wezterm
  scoop install tree-sitter                          # no winget package
  scoop bucket add nerd-fonts && scoop install FiraMono-NF
  ```

- **Linux** — your package manager for `nodejs npm`, `ripgrep`, `fd`, and
  `tree-sitter`; **starship** and **uv** via their official `curl | sh` installers
  (starship.rs / astral.sh); **Neovim ≥ 0.11** from a recent build (distro
  packages are often older — PPA / AppImage / `bob` / Homebrew) and **WezTerm**
  natively (binary on `PATH`); the FiraMono Nerd Font from the
  [Nerd Fonts release](https://github.com/ryanoasis/nerd-fonts/releases/latest).

What each is for:

- **starship** / **uv** — the prompt and Python tooling (uv builds `~/py313`).
- **Node.js + npm** — Mason's npm-based LSP servers (`pyright`, `jsonls`, `html`)
  and markdown-preview's `npx yarn` build.
- **tree-sitter CLI** — treesitter parser generation.
- **ripgrep (`rg`)** — Telescope `live_grep` / `grep_string`.
- **fd** — speeds up Telescope `find_files`; on Debian/Ubuntu and Fedora the
  package is `fd-find` and the binary `fdfind` (Telescope handles that name).
- **FiraMono Nerd Font** — Neovim's icons (neo-tree, lualine, which-key, fidget)
  and WezTerm glyphs.
- **Neovim ≥ 0.11** — the config uses the `vim.lsp.config` API introduced in 0.11.
- **C compiler (`gcc`/`clang`/`cc`) + `make`** — nvim-treesitter compiles parsers
  from C, and `telescope-fzf-native.nvim` builds with `make` (on macOS both come
  with the Xcode Command Line Tools that Homebrew requires).
- **WezTerm** — the terminal; on Linux a native install is assumed (binary on
  `PATH`); see [WezTerm](#wezterm-wezterm).
- **TeX distribution + PDF viewer** *(optional)* — only for LaTeX via VimTeX /
  the `texlab` LSP.

**Windows prerequisites:** **Git for Windows** provides the bash that runs
`init.sh`, and WezTerm launches `C:/Program Files/Git/bin/bash.exe` as its shell —
it must be at that path. Turn on **Developer Mode** (or use an elevated shell) so
`init.sh` can create the real symlinks.

### Handled inside Neovim

On first launch, **Mason** auto-installs the LSP servers (`pyright`, `jsonls`,
`html`, `lua_ls`, `rust_analyzer`, `texlab`) and `stylua` declared in
`plugins/lsp-config.lua`. `rust_analyzer` / `texlab` arrive as standalone
binaries but need a Rust toolchain / TeX install to be useful.

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
  background mux server that reattaches on next launch — the `tmux detach`/`attach`
  equivalent (survives closing the window, not a reboot). On Linux the distro
  launchers don't use it without help (collapsed below).

<details>
<summary><b>Why the Linux launchers need extra handling</b> (the <code>.desktop</code> entry and <code>Ctrl+Alt+T</code>)</summary>

`default_gui_startup_args` only applies when `wezterm-gui` is launched with **no
subcommand**: on Windows the `default_prog`/shortcut flow does exactly that, but
Linux's distro `.desktop` entry hardcodes `Exec=wezterm start --cwd .`, whose
explicit `start` overrides it and opens non-persistent local-domain windows. So
`init.sh`'s `setup_os` (in `init_linux.sh`) installs a user-level
`org.wezfurlong.wezterm.desktop` (tracked at
`wezterm/org.wezfurlong.wezterm.desktop`) that shadows the system one and
launches `wezterm-gui connect unix`. It assumes a native install (binary on
`PATH`); Flatpak/Snap would need a different `Exec`.

**The `.desktop` override only fixes the applications-list launcher — not
`Ctrl+Alt+T`.** That chord is GNOME's `media-keys` *terminal* action, which
launches `x-terminal-emulator` (on Ubuntu, `update-alternatives`'d to the
wezterm package's `open-wezterm-here`, i.e. `wezterm start --cwd …`) rather than
the `.desktop` entry, so it hits the same non-persistent `start` path.
`setup_os`'s `bind_terminal_shortcut` takes the shortcut over at the user level:
a GNOME custom keybinding (`gsettings`, relocatable schema path
`…/custom-keybindings/wezterm-mux/`) bound to `<Primary><Alt>t` → `wezterm-gui
connect unix`, plus unbinding the built-in `terminal` key so the chord doesn't
double-fire. This is **the one place init writes live user settings (dconf)
instead of symlinking a tracked file**, so it's not reverted by removing a
symlink. It's GNOME-gated (skips silently when the `media-keys` schema is absent
— other DEs would each need their own mechanism), idempotent, root-free, and the
`terminal` unbind is guarded for GNOME builds that lack that key.

</details>

The config-dir symlinking and the Windows-only login-shell `default_prog` are
driven by `init.sh`/`shellenv` and documented under [Shell](#shell-bashrc-bash_aliases)
below. `wezterm/tmux-testing.md` is a manual test checklist for the command
layer.

### Shell (`bashrc`, `bash_aliases`)

- **OS detection has a single source of truth: `shellenv`** (symlinked to
  `~/.shellenv`), sourced by both `bashrc` (at startup) and `init.sh` (at install
  time, from the repo copy since the symlink may not exist yet) so they never
  disagree. It sets `SYSTEM_OS` (`Linux`/`macOS`/`Windows`/`Unknown`) and defines
  the shared helpers both rely on: `have_cmd` (a quiet `command -v` wrapper),
  `winpath` (MSYS↔Windows path converter), and `path_prepend` (below). Keep it
  side-effect-free apart from setting `SYSTEM_OS`.
- **OS-specific code lives in per-platform files**, not inline in `bashrc`, which
  sources `~/.bashrc_<os>` (lowercased `SYSTEM_OS`, same dispatch as
  `init_<os>.sh`) early — before the interactive guard, so e.g. the Windows `HOME`
  normalization always runs. Add OS-only behavior to the matching `bashrc_<os>`;
  keep `bashrc`/`bash_aliases` cross-platform. New platform files also need adding
  to `init.sh`'s `setup_dotfiles`.
- **`bash_profile` just sources `~/.bashrc`** so *login* shells load the same
  config as non-login ones — notably the `bash -l` WezTerm launches on Windows and
  the login shell macOS terminals use by default.
- **Neovim's config dir is platform-specific.** `init.sh`'s `nvim_config_dir`
  symlinks `nvim/` to `$XDG_CONFIG_HOME/nvim` if set, else `~/AppData/Local/nvim`
  on Windows or `~/.config/nvim` elsewhere — matching where Neovim looks.
- **WezTerm's config dir is `~/.config/wezterm` everywhere** (unlike Neovim, no
  AppData on Windows); `wezterm_config_dir` honors `$XDG_CONFIG_HOME` too. On
  Windows, `wezterm.lua` launches Git Bash as a **login** shell (`bash.exe -l -i`);
  without `-l`, `/etc/profile` never runs and `/usr/bin` is off `PATH`, so
  git/starship can't be found.
- **`init.sh`'s OS-specific setup lives in per-OS files** (`init_<os>.sh`), sourced
  from the repo copy (init-time only, not symlinked). `init.sh` defines a no-op
  `setup_os` hook that a present `init_<os>.sh` overrides (and can set env like
  `MSYS`): `init_linux.sh` adds the WezTerm desktop entry + GNOME shortcut;
  `init_windows.sh` only sets `MSYS`; macOS has no file. Small per-OS *values* (nvim
  dir, pyenv path) stay as inline `SYSTEM_OS` branches; only *procedures* move out.
- **The prompt comes from starship** (which you install). `bashrc` runs `starship
  init bash` when it's present, else falls back to a simple, portable `PS1`, so the
  shell stays usable without it.
- **`PATH` additions go through `path_prepend`** (from `shellenv`): it moves an
  existing dir to the front, dropping any earlier occurrence. `bashrc` calls it
  last — after the tool-env scripts (`~/.local/bin/env`, `~/.cargo/env`) — so the
  last call wins and re-sourcing is idempotent; `~/.local/bin` is prepended last
  for top priority. `init.sh`'s `ensure_tools_on_path` calls it before
  `setup_pyenv`/`setup_completions` so a `uv` you installed to `~/.local/bin` is
  found this run.
- `cd` is overridden to use `pushd` (a directory stack); `vdirs` lists it
  newest-first, capped to the top 10 so a long-lived stack stays readable
  (`vdirs N` for the top N, `vdirs all` for the whole stack).
- `pyenv` alias activates the `~/py313` uv venv created by `init.sh`. It's
  OS-gated (lives in the `bashrc_<os>` files, not `bash_aliases`, since those are
  sourced after the platform files): `bin/activate` on Unix, `Scripts/activate`
  on Windows. `setup_pyenv` resolves the same path via `SYSTEM_OS`.
- **Tool completions are generated at install time, not eval'd at startup.**
  `init.sh`'s `setup_completions` writes each tool's bash completion (uv, uvx,
  pixi, rustup, cargo) to `~/.local/share/bash-completion/completions/<cmd>`,
  where bash-completion lazy-loads it on the first TAB for that command — so
  there's no shell-startup cost (uv's script alone is ~10k lines). Each file is
  gated on its command existing (an absent tool generates nothing), and the
  `cargo` file is emitted by `rustup`. The files don't auto-update — re-run
  `init.sh` to refresh them after a tool upgrade.
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

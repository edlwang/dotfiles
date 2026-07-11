# dotfiles

> Runs on **Linux**, **macOS**, and **Windows** (via Git Bash).

Personal dotfiles for bash, Neovim, and WezTerm. `init.sh` symlinks the tracked
files in this repo into `$HOME`, so **editing a file here immediately changes the
live config** (the symlinks point back into this repo). There is no build step —
the "product" is the configuration itself — but `check.sh` provides repeatable
repository smoke checks. The Neovim config is the bulk of the repository.

## Contents

- [Quickstart](#quickstart)
- [Repository layout](#repository-layout)
- [Common tasks](#common-tasks)
- [Dependencies](#dependencies)
- [Architecture](#architecture) — [Neovim](#neovim-nvim) · [WezTerm](#wezterm-wezterm) · [Shell](#shell-bashrc-bash_aliases) · [Shared agent instructions](#shared-agent-instructions-shared) · [Claude Code](#claude-code-config-claude) · [Codex](#codex-config-codex) · [Antigravity](#antigravity-config-geminiantigravity-cli) · [jai sandbox](#sandboxing-ai-agents-with-jai-jai)
- [Optional per-machine git identity](#optional-per-machine-git-identity)

## Quickstart

```bash
git clone https://github.com/edlwang/dotfiles.git "$HOME/dotfiles/"
bash "$HOME/dotfiles/init.sh"
source ~/.bashrc   # or open a new shell
"$HOME/dotfiles/doctor.sh"
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
├── doctor.sh           Read-only dependency, version, and symlink diagnostics
├── check.sh            Read-only repository configuration smoke checks
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
│   ├── shell-integration.sh            OSC 7 cwd reporting, vendored from upstream
│   └── tmux-testing.md                 Manual test checklist for the command layer
├── shared/             Config shared across every agent → symlinked per-agent
│   └── agent-instructions.md   Global instructions → ~/.claude/CLAUDE.md, ~/.codex/AGENTS.md, ~/.gemini/GEMINI.md
├── claude/             Claude Code config → symlinked into ~/.claude
│   └── settings.json
├── codex/              Codex config → symlinked into ~/.codex
│   ├── config.toml
│   ├── prompts/            Custom /prompts:<name> files → ~/.codex/prompts/
│   └── rules/              Starlark command rules (forbids git push) → ~/.codex/rules/
├── gemini/antigravity-cli/  Antigravity config → symlinked into ~/.gemini/antigravity-cli/
│   ├── settings.json
│   └── skills/         Antigravity skills (like scope, scopenext, and dispatch)
├── jai/                jai(1) sandbox config → symlinked into ~/.jai/
│   ├── default.conf        }
│   ├── agents.common       }  Shared agent directives, included by each agent .conf
│   ├── claude.conf         }  Per-jail .conf (defaults) + .jail (mode) → ~/.jai/
│   ├── claude.jail         }  (claude, codex, and agy jails run in strict mode)
│   ├── codex.conf          }
│   ├── codex.jail          }
│   ├── agy.conf            }
│   ├── agy.jail            }
│   ├── default.jail        }
│   └── jairc               Bash functions for jai shells → ~/.jai/.jairc
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
| Diagnose the environment | `./doctor.sh` (read-only; checks dependencies and exact symlink targets) |
| Check repository configuration | `./check.sh` (read-only; syntax, prompt parity, whitelists, and isolated app loading) |
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

`doctor.sh` diagnoses the installed environment: commands, versions, optional
features, and symlinks. `check.sh` instead validates the repository files being
edited. Its application checks use temporary home and XDG directories; the
Neovim check loads the core editor modules under `--clean` so lazy.nvim cannot
bootstrap or update plugins. The checks do not update plugins or tracked files.
An unavailable optional parser or application is reported as `SKIP`, never as a
pass; failures still make the command exit nonzero.

## Dependencies

Derived by reading the configs, not by provisioning a clean machine — treat it
as the known set, not a guarantee.

### Install yourself

`init.sh` is **config-only**: it symlinks the configs and, if `uv` is already
present, creates the `~/py313` venv — but it installs **no** tools. Run
`./doctor.sh` afterward (and whenever the environment seems incomplete) to check
required commands, the Neovim 0.11 minimum, the platform clipboard provider,
and every exact symlink installed by `init.sh`. It makes no changes and exits
nonzero only for missing hard requirements or broken required links. Optional
features such as bash-completion, TeX/PDF support, jai, Rust, Stylua, the py313
activation script, and eligible generated completions are reported as warnings.

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

  winget/scoop update only the *persisted* PATH, so **open a new shell before
  running `init.sh`** — otherwise it won't see `uv` and will skip the `~/py313`
  venv (re-run it in a fresh shell to create it).

- **Linux** — your package manager for `nodejs npm`, `ripgrep`, `fd`,
  `tree-sitter`, and a clipboard tool (`xclip`/`xsel` on X11, `wl-clipboard` on
  Wayland — see the rationale below); **starship** and **uv** via their official
  `curl | sh` installers (starship.rs / astral.sh); **Neovim ≥ 0.11** from a
  recent build (distro packages are often older — PPA / AppImage / `bob` /
  Homebrew) and **WezTerm** natively (binary on `PATH`); the FiraMono Nerd Font
  from the [Nerd Fonts release](https://github.com/ryanoasis/nerd-fonts/releases/latest).

  - **Aurora** — Homebrew (the standard path on this atomic Fedora image):

    ```bash
    brew install starship uv npm ripgrep fd tree-sitter-cli neovim wl-clipboard
    brew tap wezterm/wezterm-linuxbrew
    brew install --HEAD wezterm/wezterm-linuxbrew/wezterm
    brew install --cask font-fira-mono-nerd-font
    ```

    For the optional agent sandbox
    ([jai](#sandboxing-ai-agents-with-jai-jai)), build jai from source —
    it's not packaged for Aurora. The trick on an atomic image is that
    `/usr/local` is a writable, `/var`-backed path (`/var/usrlocal`), so it's
    the right home for the setuid binary — it survives image updates with no
    `rpm-ostree` layering. Point `./configure` at it explicitly with
    `--prefix=/usr/local`; under the brew build environment the prefix won't
    default there on its own. The base image already has a C++23 compiler
    (`g++`), `make`, and `git`; brew supplies the autotools and pandoc the git
    build needs:

    ```bash
    brew install autoconf automake pandoc
    git clone https://github.com/stanford-scs/jai.git
    cd jai && ./autogen.sh && ./configure --prefix=/usr/local && make
    sudo make install        # installs the setuid-root binary into /usr/local
    sudo systemd-sysusers    # creates the unprivileged `jai` user for strict mode
    ```

What each is for:

- **starship** / **uv** — the prompt and Python tooling (uv builds `~/py313`).
- **Node.js + npm** — Mason's npm-based LSP servers (`pyright`, `jsonls`, `html`)
  and markdown-preview's `npx yarn` build.
- **tree-sitter CLI** — treesitter parser generation.
- **ripgrep (`rg`)** — Telescope `live_grep` / `grep_string`.
- **fd** — speeds up Telescope `find_files`; the package is `fd-find` on both
  Debian/Ubuntu (binary `fdfind`, which Telescope handles) and Fedora (binary
  `fd`).
- **FiraMono Nerd Font** — Neovim's icons (neo-tree, lualine, which-key, fidget)
  and WezTerm glyphs.
- **Neovim ≥ 0.11** — the config uses the `vim.lsp.config` API introduced in 0.11.
- **git** — lazy.nvim bootstraps itself with `git clone` and clones/updates every
  Neovim plugin through git, so it's required on **every** platform, not just
  Windows. macOS gets it with the Xcode Command Line Tools, Windows from Git for
  Windows, Linux from your package manager.
- **C compiler (`gcc`/`clang`/`cc`) + `make`** — nvim-treesitter compiles parsers
  from C, and `telescope-fzf-native.nvim` builds with `make` (on macOS both come
  with the Xcode Command Line Tools that Homebrew requires).
- **WezTerm** — the terminal; on Linux a native install is assumed (binary on
  `PATH`); see [WezTerm](#wezterm-wezterm).
- **Clipboard tool** *(Linux only)* — `<leader>y` / `<leader>Y` yank to the system
  clipboard (the `"+` register), which needs `xclip`/`xsel` (X11) or `wl-clipboard`
  (Wayland). macOS (`pbcopy`) and Windows (`clip.exe`) have one built in. Without a
  provider the yank silently no-ops; everything else still works.
- **bash-completion** *(optional)* — the shell's tab-completion loader. `bashrc`
  sources it and `init.sh` writes per-tool completion files into its completions dir
  for it to lazy-load; without the package those files never load and you fall back
  to bash's default completion. On macOS it's Homebrew's `bash-completion@2`.
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
- **New splits/tabs open in the current pane's directory.** The split binds use
  `domain = "CurrentPaneDomain"`, but WezTerm only inherits the cwd if the shell
  reports it via the OSC 7 escape sequence each prompt. The distro emitters
  (`vte.sh` / systemd) don't cover every platform and get dropped once starship
  owns the prompt, so `bashrc` instead sources WezTerm's own
  `wezterm/shell-integration.sh` (vendored verbatim from
  [upstream](https://github.com/wezterm/wezterm/blob/main/assets/shell-integration/wezterm.sh) —
  refresh with `curl` to that path; it also adds OSC 133 semantic zones and user
  vars). It's sourced **before** starship so its bundled bash-preexec is in place
  for starship to cooperate with (`precmd_functions`) instead of clobbering it.
- **Leader symbol keys (`%` `"` `&` `:` `[` `]` `,`) go through the
  `leader_symbol()` helper.** A bare `{ key = "%" }` matches by physical key
  position and silently fails for shifted symbols; the helper binds by produced
  character (with `mapped:`, and both with and without `SHIFT`, since WezTerm
  versions disagree on whether the shift is reported). Add new symbol binds
  through it, not as plain `{ key = …, mods = L }` entries.
- **Multiplexing is always on; persistence is opt-in (tmux-style).** A plain
  `wezterm` launch is an independent, ephemeral terminal on the in-process local
  domain. `config.unix_domains` defines a background mux server but nothing
  auto-connects to it — run `wezterm connect unix` (new window), `wezterm connect
  --new-tab unix` (tab in the active window), or pick the `unix` domain from the
  leader launcher (`Ctrl+Space s`) for persistent panes/tabs that reattach on the
  next `connect` — the `tmux detach`/`attach` equivalent (survives closing the
  window, not a reboot).

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
- **`bashrc` sources the system-wide `/etc/bashrc`** where the distro keeps one at
  that path (Fedora/RHEL family, macOS). There it's what runs `/etc/profile.d/*.sh`
  for non-login *interactive* shells (the Homebrew/Linuxbrew shellenv, terminal cwd
  tracking, …), which a WezTerm pane would otherwise miss — this is what makes
  brew-installed tools work on Aurora. It mirrors the stock Fedora `~/.bashrc`;
  Debian keeps its system file at `/etc/bash.bashrc` (auto-sourced by interactive
  bash), so the `-f` guard cleanly no-ops there. It runs before the rest of
  `bashrc`, so starship's prompt and the `HIST*`/`PATH` settings override anything
  it sets.
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
  `setup_os` hook that a present `init_<os>.sh` can override (and can set env like
  `MSYS`): `init_windows.sh` only sets `MSYS`; Linux and macOS have no file. Small
  per-OS *values* (nvim dir, pyenv path) stay as inline `SYSTEM_OS` branches; only
  *procedures* move out.
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
- `pyenv` alias activates the `~/py313` uv venv created by `init.sh`. It's a
  cross-platform single alias in `bash_aliases` that delegates to `svenv`, which
  probes both the `bin/activate` (Unix) and `Scripts/activate` (Windows) layouts;
  `setup_pyenv` still resolves the same path via `SYSTEM_OS`.
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

### Shared agent instructions (`shared/`)

The global instructions are **one source of truth** for every agent:
`shared/agent-instructions.md` holds the working preferences (correctness-first,
verify-before-claiming, the Git rules) that Claude Code, Codex, and Antigravity
all read. They were byte-identical across the three tools, so rather than keep
three copies in sync, `init.sh` symlinks this one file into each agent's home
under the name that tool expects — `~/.claude/CLAUDE.md` for Claude,
`~/.codex/AGENTS.md` for Codex, `~/.gemini/GEMINI.md` for Antigravity (note:
Antigravity reads global rules from `~/.gemini/GEMINI.md`, *not* from
`AGENTS.md` inside its app-data dir). **Edit working preferences here** and every
agent picks up the change on its next run; the per-tool dirs below hold only
genuinely tool-specific config (settings, prompts/skills, rules). `shared/` sits
outside the per-tool `.gitignore` deny blocks, so files there are tracked
normally.

One rule here has a subtlety worth flagging: the Git section requires commit
attribution to **name the model that actually did the work**, read from the
agent's own system prompt. A *dispatched* subagent can't always identify its own
model that way (gemini flash under Antigravity guessed wrong), so the
`dispatch` command/skill (in all three tools) tells the dispatcher to hand the
subagent the model it was dispatched at — otherwise the attribution in its
commits is a guess.

### Claude Code config (`claude/`)

Default Claude Code config lives in `claude/` (e.g. `settings.json`). `init.sh`'s
`setup_agent` step symlinks **each top-level entry** of `claude/` into
`~/.claude/` — it globs the directory, so nothing to edit on the symlink side —
and leaves the rest of `~/.claude/` (credentials, history, sessions, jobs — all
runtime state) untouched. Because everything in `claude/` is symlinked, **only
put config files here**, never runtime state or secrets.

**Git tracking uses a whitelist, decoupled from that glob.** `.gitignore` ignores
all of `claude/` and re-includes only `settings.json`, `commands/`, and
`agents/` — a fail-safe so credentials or runtime state can never be
committed even if copied in. (Global instructions are shared, not tracked here —
see [Shared agent instructions](#shared-agent-instructions-shared).) The catch: `setup_agent` will symlink *anything*
you drop in `claude/`, but git **silently ignores** a new config type (e.g.
`output-styles/`, a `statusline.sh`) until you add a matching `!claude/<name>`
line — plus `!claude/<name>/**` for a directory — to `.gitignore`. So adding a
new *kind* of config is a two-step: drop the file, then whitelist it.

`setup_agent` symlinks each **top-level** entry, so a subdirectory like
`claude/commands/` becomes a whole-directory symlink (`~/.claude/commands` →
repo). If a real `~/.claude/commands/` already exists, `setup_symlink` moves it
to the backup dir and replaces it with the link — so only track directories whose
contents you fully own in the repo, not ones Claude or plugins also write to at
runtime.

### Codex config (`codex/`)

Codex config lives in `codex/` and works exactly like [`claude/`](#claude-code-config-claude):
`init.sh`'s `setup_agent` step globs each top-level entry into `~/.codex/` and
leaves runtime state (`auth.json`, history, sessions) untouched, and `.gitignore`
whitelists only config kinds. The tracked pieces mirror the Claude ones:
`config.toml` (settings — `model` selects the exact model and
`model_reasoning_effort` stands in for `effortLevel`; Codex has no `config.toml`
command-deny setting, so the "never push" rule lives in `AGENTS.md`) and
`prompts/` (custom `/prompts:<name>` commands, the `commands/` analog). The
`scope` and `scopenext` prompts recommend both an available exact model ID and a
reasoning effort; unlike the Claude and Antigravity copies, they intentionally
avoid a hard-coded model menu that can become stale or differ by account. Its
`AGENTS.md` is the shared
[`shared/agent-instructions.md`](#shared-agent-instructions-shared) symlinked in,
not a Codex-specific file. Since Codex has no `config.toml` command-deny, `git push` is blocked in
layers: `config.toml`'s read-only sandbox stops in-sandbox pushes (network write),
`rules/no-push.rules` marks `git push` `forbidden` if Codex escalates it outside
the sandbox (the analog to Claude's `permissions.deny`), and `AGENTS.md` keeps the
"never push" instruction. These are agent-scoped; add a git hook if you also want
your own pushes blocked locally.

Because config is shared but auth is per-home, the `codex` jail sees this same
config once `init.sh` runs inside it, yet keeps its own login — see the jail's
note below on why we deliberately don't expose the real `~/.codex`. On a host
with an existing `~/.codex/config.toml`, the first setup backs it up and replaces
it with the tracked configuration.

### Antigravity config (`gemini/antigravity-cli/`)

Antigravity CLI config lives in `gemini/antigravity-cli/` and works exactly like
[`claude/`](#claude-code-config-claude): `init.sh`'s `setup_agent` step globs each
top-level entry into `~/.gemini/antigravity-cli/` and leaves runtime state
(credentials, history, sessions, jobs) untouched, and `.gitignore` whitelists only
config kinds — here `settings.json` and `skills/` (the same two-step gotcha
applies to adding a new kind: whitelist it with `!gemini/antigravity-cli/<name>`,
plus `!gemini/antigravity-cli/<name>/**` for a directory, or git silently ignores
it). Global instructions live at `~/.gemini/GEMINI.md` (a symlink to
[`shared/agent-instructions.md`](#shared-agent-instructions-shared)), which is
where Antigravity reads global rules — not the `AGENTS.md` that `setup_agent`
also creates inside `~/.gemini/antigravity-cli/` (that copy is vestigial).

`settings.json` carries the theme, default model, and a `permissions.deny` rule
for `command(git push)` — the direct analog to Claude's `permissions.deny`, since
Antigravity uses the same allow/deny command-permission model (deny wins over
allow). `GEMINI.md` keeps the "never push" instruction as a back-stop.

**Authoring skills.** Antigravity skills work differently from Claude's
`commands/` and Codex's `prompts/`: the CLI auto-loads a `skills/<name>/SKILL.md`
when it semantic-matches the user's intent against the frontmatter `description`,
so there is **no `$ARGUMENTS` substitution** to receive a typed target. Write the
`description` to be trigger-oriented (include example phrases — it's the router's
only signal), give the body an H1 title, and have the instructions derive the
target from the user's request rather than a placeholder. Keep each under ~500
words. The bundled `scope`/`scopenext`/`dispatch` skills mirror the Claude/Codex
commands of the same name, adapted to this model. Note the CLI reads global skills from
`~/.gemini/antigravity-cli/skills/`, which is distinct from the Antigravity IDE's
`~/.gemini/config/skills/` — if a future release unifies them, revisit this path.

### Sandboxing AI agents with jai (`jai/`)

[jai](https://jai.scs.stanford.edu/) is a lightweight sandbox for AI agents:
`jai cmd` runs `cmd` with the current directory (and below) writable, the rest of
the filesystem read-only, and sensitive files masked. The `jai/` dir holds the
per-jail config that `init.sh`'s
`setup_dotfiles` symlinks into `~/.jai/` (each file as `~/.jai/<name>`, except
`jairc` → `~/.jai/.jairc`). Adding a new jail is drop-in: a new
`<name>.conf`/`<name>.jail` pair in `jai/` is picked up by that symlink loop with
no `init.sh` edit.

The **`claude` jail** runs Claude Code in **strict mode** (`claude.jail`): under
the unprivileged `jai` user, with an empty but *persistent* home at
`~/.jai/claude.home`, the working directory mapped in read-write, and everything
else read-only. `claude.conf` names the jail and includes `agents.common` — the
shared file (factored out because all three agent `.conf`s carried it verbatim)
that exposes the dotfiles repo **read-only** (`rdir dotfiles`) so the symlinked
configs resolve inside, and prepends the jail's `~/.local/bin` to `PATH` so the
in-jail `claude` binary is found. Read-only is deliberate: `dir` would grant
read-**write**, letting a jailed agent launched from any directory rewrite
`bashrc`, `init.sh`,
`claude/settings.json`, or `shared/agent-instructions.md` — files that run
*unjailed* in your next session, a persistence/escape path that defeats strict
mode. When you actually want to edit the dotfiles from inside a jail, launch it
writable with `jaicl -d dotfiles` (grants read-write regardless of cwd). Note
both `-d` and `-x` take a mandatory directory argument — omitting it (bare
`jaicl -d`/`jaicl -x`) is a usage error, not a shortcut. Config that Claude
itself persists (model, effort)
lands in the jail-home `~/.claude.json`, not the repo, so routine use is
unaffected.

The **`codex` jail** (`codex.jail`) applies the same strict-mode recipe to
OpenAI Codex, with a persistent home at `~/.jai/codex.home`. `codex.conf` mirrors
`claude.conf` — the same `agents.common` include (`rdir dotfiles` plus
`~/.local/bin` on `PATH`) — since Codex's
standalone installer lands the binary in `~/.local/bin` and keeps its package and
state under `~/.codex`, both inside the jail's own home. Its config comes from the
version-controlled [`codex/`](#codex-config-codex) dir, symlinked into the jail's
`~/.codex` when you run `init.sh` inside the jail — so we deliberately do **not**
`dir .codex`; the real `~/.codex` (and its credentials) is never exposed, and the
jailed Codex logs in with its own auth. The working directory's `.git` stays
writable (inherited from the read-write cwd, not downgraded), so Codex can commit.

The **`agy` jail** (`agy.jail`) applies the strict-mode recipe to Google
Antigravity, with a persistent home at `~/.jai/agy.home`. `agy.conf` mirrors the
others, including the same `agents.common` (`rdir dotfiles` plus `~/.local/bin` on
`PATH`, where the CLI installer puts `agy`).

The git push deny rules in `claude/settings.json`, `codex/rules/no-push.rules`,
and `gemini/antigravity-cli/settings.json` are convenience guardrails (they don't
catch aliases, `sh -c "git push"`, or flag-separated variants); the actual
security boundary is the jail itself — no push credentials in the jail home.

**One-time setup.** Because a strict jail starts with an empty home, the agent
has to be installed *into* the jail, and the dotfiles symlinked *inside* it as
well as outside — running `init.sh` in the jail recreates `~/.claude/CLAUDE.md`,
`settings.json`, `~/.bashrc`, the `~/.config/{nvim,wezterm}` links, etc. in the
jail's own home (all pointing back at the `rdir dotfiles`-exposed repo), which is
why the `.conf` files don't need to grant your real `~/.claude` or `~/.config`.
First [install jai](#dependencies) itself (a setuid-root binary; on Aurora,
build it from source per the [Aurora](#install-yourself) install block), then,
for each agent you want to sandbox:

1. **Install the agent into its jail** — pipe the official installer through jai
   so the binary lands in the jail's home, not your real one. Both installers
   default to `~/.local/bin`, which each `.conf` puts on `PATH`:

   ```bash
   # Claude Code → ~/.jai/claude.home/.local/bin
   curl -fsSL https://claude.ai/install.sh | jai -D -mstrict -j claude bash

   # Codex → ~/.jai/codex.home/.local/bin (package + state under ~/.codex)
   curl -fsSL https://chatgpt.com/codex/install.sh | jai -D -mstrict -j codex sh

   # Antigravity → ~/.jai/agy.home/.local/bin
   curl -fsSL https://antigravity.google/cli/install.sh | jai -D -mstrict -j agy bash
   ```

   (`-D` withholds the current directory, `-mstrict` matches the jail's mode,
   `-j <name>` names the jail. The install targets the jail home even without
   `-C <name>`, because `-j`/`-mstrict` alone select it.)

2. **Run `init.sh` outside the jail** — the normal [Quickstart](#quickstart)
   step. This creates the `~/.jai/*.conf`/`*.jail` symlinks so `jai claude` /
   `jai codex` / `jai agy` resolve this config, and links your configurations,
   `~/.bashrc`, etc.:

   ```bash
   bash ~/dotfiles/init.sh
   ```

3. **Run `init.sh` again inside each jail**, so the jail's empty home gets the
   same symlinks and the agent sees your config:

   ```bash
   cd ~/dotfiles && jai -C claude ./init.sh
   cd ~/dotfiles && jai -C codex ./init.sh
   cd ~/dotfiles && jai -C agy ./init.sh
   ```

Then launch an agent in the sandbox with `jai claude` (alias `jaicl`),
`jai codex` (alias `jaico`), or `jai agy` (alias `jaiag`) from any project
directory; `jai -C <name>` opens a shell with the same permissions, handy for
inspecting exactly what the agent can see.

## Optional per-machine git identity

`gitconfig` ends with `[include] path = ~/.gitconfig.local`. Create that
untracked file to override the committed name/email on a given machine.

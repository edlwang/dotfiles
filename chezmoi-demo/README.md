# chezmoi-demo

A **demonstration** of what this dotfiles repo would look like managed by
[chezmoi](https://www.chezmoi.io/) instead of the current `init.sh` +
symlink approach. Nothing here touches your live config — it's a parallel,
self-contained source tree you can read, diff, and dry-run.

It ports the shell layer concretely (real, templated files) and *describes* the
big config trees (Neovim, WezTerm, Claude) rather than duplicating them.

## The core model

chezmoi separates **source state** (this tree, in git) from **target state**
(your `$HOME`). You run `chezmoi apply` to make `$HOME` match the source. Source
filenames are encoded with attribute prefixes/suffixes (`dot_`, `.tmpl`,
`private_`, …) that tell chezmoi the target name, permissions, and whether to
template it. Per-machine differences are handled by **Go templates** instead of
separate per-OS files, and one-time setup by **`run_` scripts** instead of an
installer.

```text
chezmoi-demo/home/                 ← the chezmoi source directory
├── .chezmoi.toml.tmpl             → ~/.config/chezmoi/chezmoi.toml (config + prompts)
├── .chezmoiignore                 → which targets to skip (templated, per-OS)
├── .chezmoiexternal.toml          → network-fetched files (the Nerd Font)
├── dot_bashrc.tmpl                → ~/.bashrc        (templated; OS blocks inline)
├── dot_bash_aliases               → ~/.bash_aliases  (plain)
├── dot_bash_profile               → ~/.bash_profile  (plain)
├── dot_shellenv                   → ~/.shellenv      (plain; runtime helpers)
├── dot_gitconfig.tmpl             → ~/.gitconfig     (identity from prompts)
└── .chezmoiscripts/               (run, not copied to $HOME)
    ├── run_once_before_10-install-tools.sh.tmpl
    ├── run_onchange_after_20-create-py313-venv.sh.tmpl
    └── run_onchange_after_30-bash-completions.sh.tmpl
```

## Mapping: current setup → chezmoi

| Today | chezmoi equivalent |
| --- | --- |
| `init.sh` `setup_symlink` loop | `chezmoi apply` (built in; no installer to maintain) |
| Symlink so edits are live | `mode = "symlink"` for plain files; templates need `chezmoi apply` |
| `shellenv` `SYSTEM_OS` + `bashrc` sourcing `bashrc_<os>` | `{{ .chezmoi.os }}` blocks inside `dot_bashrc.tmpl` |
| `bashrc_linux` / `bashrc_macos` / `bashrc_windows` | folded into the templated `dot_bashrc.tmpl` (no separate files) |
| `init.sh` `install_tools` + `init_windows.sh` override | `run_once_before_10-install-tools.sh.tmpl` (OS via template) |
| `init.sh` `setup_pyenv` | `run_onchange_after_20-create-py313-venv.sh.tmpl` |
| `init.sh` `setup_completions` | `run_onchange_after_30-bash-completions.sh.tmpl` |
| `~/.gitconfig.local` per-machine identity | `promptStringOnce` in `.chezmoi.toml.tmpl` → `.name`/`.email` |
| `nvim_config_dir` / `wezterm_config_dir` (XDG/AppData branching) | `dot_config/nvim`, `dot_config/wezterm` (+ a `symlink_` shim on Windows for nvim's AppData path) |
| `.gitignore` whitelist for `claude/` | `private_dot_claude/` + `.chezmoiignore` |
| Linux-only WezTerm `.desktop` (installed by `init_linux.sh`) | tracked file + `.chezmoiignore` skips it off Linux |
| `init.sh` install of starship/uv via `curl|sh` | same script, plus optional `.chezmoiexternal.toml` for fetched assets (Nerd Font) |
| FiraMono Nerd Font (manual dep) | `.chezmoiexternal.toml` downloads + unpacks it |
| Re-run `init.sh` to refresh | `chezmoi update` (git pull + apply) |

## Naming attributes used here

- `dot_bashrc` → `~/.bashrc` (`dot_` = leading `.`).
- `*.tmpl` → rendered as a Go template at apply time.
- `private_dot_claude/` → `~/.claude` with `0700`/`0600` perms (for the big
  config trees; not physically built in this demo).
- `.chezmoiscripts/run_once_before_*` → script run once, before applying files.
- `.chezmoiscripts/run_onchange_after_*` → script re-run when its contents
  change, after applying files.

Other attributes you'd reach for in a full port: `executable_` (+x),
`symlink_` (target file is a symlink), `exact_` (dir prunes unmanaged files),
`encrypted_` (secrets).

## Templating replaces the OS split

Instead of `bashrc` dispatching to one of three `bashrc_<os>` files via
`SYSTEM_OS`, `dot_bashrc.tmpl` inlines the per-OS bits:

```bash
{{ if eq .chezmoi.os "windows" -}}
export HOME="$(winpath "$HOME")"
alias pyenv="source $HOME/py313/Scripts/activate"
{{ else if eq .chezmoi.os "darwin" -}}
alias ls='ls -G'
alias pyenv="source $HOME/py313/bin/activate"
{{ else -}}
alias ls='ls --color=auto'
alias pyenv="source $HOME/py313/bin/activate"
{{ end }}
```

`shellenv` is kept only for its `path_prepend` / `winpath` helpers, which act on
**runtime** state (the live `$PATH`, the running shell's `$HOME`) that apply-time
templating can't precompute. The old `uname`→`SYSTEM_OS` *dispatch*, by contrast,
is an apply-time fact, so it moves into the templates — nothing in the rendered
config consults `SYSTEM_OS` at runtime anymore, and the variable could be dropped.

## `run_` scripts replace `init.sh`

The three scripts in `.chezmoiscripts/` reproduce `install_tools`,
`setup_pyenv`, and `setup_completions`. chezmoi runs them automatically during
`apply` and tracks them: `run_once_` runs a single time, `run_onchange_` re-runs
only when the (rendered) script changes. The OS branching that lived in
`init_<os>.sh` becomes a `{{ if eq .chezmoi.os "windows" }}` block.

## Config prompt replaces `~/.gitconfig.local`

`.chezmoi.toml.tmpl` calls `promptStringOnce` for name and email at
`chezmoi init`, stores them as template data, and `dot_gitconfig.tmpl` reads
`.name` / `.email`. No committed identity, no separate untracked include file —
each machine answers once.

## Tradeoffs vs. the current symlink setup

Honest accounting, since this isn't a strict upgrade:

- **Templates aren't symlinked.** With `mode = "symlink"`, plain files
  (`dot_bash_aliases`, `dot_shellenv`) are symlinked, so edits are live — but
  templates (`dot_bashrc.tmpl`, `dot_gitconfig.tmpl`) and scripts are generated,
  so editing them needs `chezmoi apply`. Today *every* file is live via symlink.
  Workflow becomes `chezmoi edit --apply <file>` / `chezmoi apply` for templated
  files.
- **Or skip symlinks entirely.** If you don't need live editing, drop
  `mode = "symlink"` (copy mode is the default): *every* file becomes a rendered
  copy refreshed by `chezmoi apply`, which is more uniform (no "which files are
  live?" split) and removes the symlink-privilege requirement on Windows — along
  with the whole class of `init.sh` symlink-target gymnastics. `chezmoi edit
  --watch <file>` re-applies on each save if you want something close to live.
- **OS is baked at apply time.** A symlinked `bashrc` reads `SYSTEM_OS` live; a
  templated one is resolved for the machine you applied on. Fine for
  per-machine dotfiles, but it's a real behavioral change.
- **Neovim's Windows path.** chezmoi maps one source path to one target path, so
  `dot_config/nvim` → `~/.config/nvim` everywhere — but Neovim wants
  `~/AppData/Local/nvim` on Windows. You'd add a Windows-only `symlink_` shim
  (or set `XDG_CONFIG_HOME`), which is roughly what `nvim_config_dir` does today.
- **A new dependency + state dir.** chezmoi is a binary to install, and it keeps
  a copy/state under `~/.local/share/chezmoi`. The current setup needs only bash.
- **What you gain:** no hand-written installer to maintain, templating instead of
  duplicated per-OS files, prompted secrets/identity, `run_` script lifecycle
  (once/onchange), network-fetched assets (the font), and `chezmoi diff` /
  `chezmoi status` to preview before applying.

## Try it without touching your real config

These commands **dry-run only** — they never write to `$HOME`:

```bash
# Point chezmoi at this demo subtree and preview what it WOULD do.
chezmoi init   --source "$PWD/chezmoi-demo/home"
chezmoi diff   --source "$PWD/chezmoi-demo/home"     # full target diff
chezmoi apply  --source "$PWD/chezmoi-demo/home" --dry-run --verbose
```

To make the repo root itself the source in a real migration, add a
`.chezmoiroot` file at the repo root containing `chezmoi-demo/home` (chezmoi
then treats that subdir as the source), or move these files up to the root.
`chezmoi apply` (without `--dry-run`) is what actually changes `$HOME` — this
demo never runs it for you.

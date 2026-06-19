# Plan: expand `init.sh` to install the runtime toolchain

## Goal

Shrink first-time setup to a **minimal manual bootstrap**, then let `init.sh`
install and configure everything it reasonably can. Today `init.sh` installs
only `starship` and `uv` (plus a `~/py313` venv); a fresh machine still needs
Node, the tree-sitter CLI, ripgrep, and fd installed by hand before Neovim is
fully functional. This plan moves those into `init.sh`.

## Scope decisions (agreed)

- **Platforms:** all three — Linux, macOS, Windows.
- **Auto-install (add to `init.sh`):** Node.js + npm, tree-sitter CLI, ripgrep,
  fd. (Alongside the existing starship, uv.)
- **Stay manual (too fragile / machine-specific):** Neovim ≥ 0.11 and the C
  compiler + `make`. Also unchanged: WezTerm, the Nerd Font, any TeX
  distribution, and the Mason-managed LSP servers + stylua.

### Why those stay manual

- **Neovim ≥ 0.11** — distro packages are often older than 0.11 (the config uses
  the `vim.lsp.config` API); installing a recent build is per-machine (PPA /
  AppImage / `bob` / brew / winget).
- **C compiler + make** — needed to compile nvim-treesitter parsers and build
  `telescope-fzf-native`; the right package/toolchain varies a lot
  (`build-essential` / Xcode CLT / MSYS2 mingw).
- **WezTerm + Nerd Font** — GUI/desktop layer; the font also renders Neovim's
  icons.
- **TeX** — large, optional (only VimTeX / `texlab`).
- **LSP servers + stylua** — Mason already installs these inside Neovim.

## Architecture

Follow the existing pattern (see AGENTS.md): the default (Unix) `install_tools`
lives in `init.sh`; a present `init_<os>.sh` overrides it. Linux and macOS now
have genuinely divergent install *procedures*, so:

- **New `init_linux.sh`** — overrides `install_tools`; detects the system
  package manager (apt/dnf/pacman/zypper) and installs via `sudo`.
- **New `init_macos.sh`** — overrides `install_tools`; installs via Homebrew.
- **Extend `init_windows.sh`** — its `install_tools` already uses winget/scoop;
  add the new tools.
- `init.sh` keeps the `install_starship` / `install_uv` (curl|sh) helpers; the
  per-OS `install_tools` reuse them on Unix. The default `install_tools`
  (Unknown OS) is unchanged.

These files are install-time only (sourced from the repo copy, not symlinked) —
same as `init_windows.sh` today.

## Per-OS install mechanics

### Linux (`init_linux.sh`)

- Detect: first of `apt-get`, `dnf`, `pacman`, `zypper`.
- Run as root via `sudo` when not already root.
- Packages: Node `nodejs npm`; ripgrep `ripgrep`; fd `fd-find` on apt/dnf
  (**binary is `fdfind`**) / `fd` on pacman/zypper.
- tree-sitter CLI: `tree-sitter` package on pacman; elsewhere
  `npm install -g tree-sitter-cli` (npm is on `PATH` right after the package
  install on Linux; the global install needs sudo).
- starship/uv: keep curl|sh (`install_starship` / `install_uv`).

### macOS (`init_macos.sh`)

- Require Homebrew; warn if absent.
- `brew install node ripgrep fd tree-sitter`.
- starship/uv: keep curl|sh.

### Windows (`init_windows.sh`)

- Prefer winget, fall back to scoop (existing logic).
- IDs / names: Node `OpenJS.NodeJS` / `nodejs`; ripgrep
  `BurntSushi.ripgrep.MSVC` / `ripgrep`; fd `sharkdp.fd` / `fd`.
- tree-sitter CLI: **scoop only** (`tree-sitter`); winget has no package, so
  warn to install it manually when only winget is present.

## Robustness rules

- **Idempotent:** guard every install with `command -v <probe>`; skip if present.
- **Non-fatal:** `init.sh` runs under `set -euo pipefail`; wrap installs with
  `|| <warn>` so one failed optional tool doesn't abort the whole run (symlinks
  are already done by then, and the `setup_pyenv` step still needs to run after).
- **Same-session PATH:** on Windows a freshly winget/scoop-installed tool isn't
  on `PATH` yet, so don't chain (e.g. `npm i -g` right after installing Node) —
  that's why tree-sitter uses scoop directly, not npm.
- **Debian fd:** the binary is `fdfind`; probing `fd` may re-trigger the
  (idempotent) install. Telescope handles `fdfind`; note it in the README.

## Notes

- The tree-sitter CLI is strictly only required to *generate* parsers (e.g.
  LaTeX, which the config deliberately omits); the listed parsers compile from C
  and need the **compiler**, not the CLI. The project still treats the CLI as a
  standard dep, so we install it.

## Verification

- `bash -n` syntax-check `init.sh`, `init_linux.sh`, `init_macos.sh`,
  `init_windows.sh`.
- The installers can't be fully exercised without mutating a real machine; treat
  runtime behavior as unverified and lean on the syntax check + review.

## Touch list

- `init.sh` — no behavior change (keep helpers + default `install_tools`).
- `init_linux.sh` — new.
- `init_macos.sh` — new.
- `init_windows.sh` — extend `install_tools`.
- `README.md` — once shipped, drop Node/tree-sitter/ripgrep/fd from the manual
  list and move them under "installed by `init.sh`".
- `AGENTS.md` — update the one-line description of what `init.sh` installs.

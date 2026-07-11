#!/bin/bash

# Read-only environment diagnostics for this dotfiles repository.
set -u

DOTFILES_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DOTFILES_PATH/shellenv"
DOTFILES_PATH="$(winpath "$DOTFILES_PATH")"
HOME="$(winpath "$HOME")"

passes=0 warnings=0 failures=0
pass() { passes=$((passes + 1)); printf 'PASS: %s\n' "$*"; }
warn() { warnings=$((warnings + 1)); printf 'WARN: %s\n' "$*"; }
fail() { failures=$((failures + 1)); printf 'FAIL: %s\n' "$*"; }

first_cmd() {
    local cmd
    for cmd in "$@"; do
        if command -v "$cmd" >/dev/null 2>&1; then printf '%s' "$cmd"; return 0; fi
    done
    return 1
}

command_version() {
    local version
    version="$("$1" --version 2>/dev/null | head -n 1)" || version=""
    printf '%s' "${version:-version unavailable}"
}

require_command() {
    local label="$1" remedy="$2" cmd
    shift 2
    if cmd="$(first_cmd "$@")"; then
        pass "$label: $(command_version "$cmd")"
    else
        fail "$label is required (tried: $*). $remedy"
    fi
}

optional_command() {
    local label="$1" purpose="$2" cmd
    shift 2
    if cmd="$(first_cmd "$@")"; then
        pass "$label (optional): $(command_version "$cmd")"
    else
        warn "$label is optional; $purpose (tried: $*)"
    fi
}

if have_cmd nvim; then
    nvim_version="$(nvim --version 2>/dev/null | head -n 1 | sed -n 's/^NVIM v\([0-9][0-9.]*\).*/\1/p')"
    nvim_major="${nvim_version%%.*}"
    nvim_minor="${nvim_version#*.}"
    nvim_minor="${nvim_minor%%.*}"
    if [[ "$nvim_major" =~ ^[0-9]+$ && "$nvim_minor" =~ ^[0-9]+$ ]] && \
       (( nvim_major > 0 || nvim_minor >= 11 )); then
        pass "Neovim $nvim_version meets the required minimum (0.11)"
    else
        fail "Neovim >= 0.11 is required (found: ${nvim_version:-unparseable}). Install a current Neovim release."
    fi
else
    fail "Neovim >= 0.11 is required. Install Neovim as described in README.md."
fi

require_command "Bash" "Install Bash (Git for Windows supplies it on Windows)." bash
require_command "Git" "Install Git; it bootstraps and updates Neovim plugins." git
require_command "WezTerm" "Install WezTerm as described in README.md." wezterm
require_command "Starship" "Install Starship from starship.rs." starship
require_command "uv" "Install uv from astral.sh/uv, then re-run init.sh." uv
require_command "Node.js" "Install Node.js and ensure node or nodejs is on PATH." node nodejs
require_command "npm" "Install npm; Mason and markdown-preview require it." npm
require_command "ripgrep" "Install ripgrep (the executable is rg)." rg
require_command "fd" "Install fd; Debian/Ubuntu may provide it as fdfind." fd fdfind
require_command "tree-sitter CLI" "Install the tree-sitter CLI." tree-sitter
require_command "make" "Install make and your platform's build tools." make
require_command "C compiler" "Install gcc, clang, or the platform C build tools." cc gcc clang cl cl.exe

case "$SYSTEM_OS" in
    Linux)
        if clipboard="$(first_cmd wl-copy xclip xsel)"; then pass "Linux clipboard provider: $clipboard"
        else fail "A Linux clipboard provider is required. Install wl-clipboard (Wayland) or xclip/xsel (X11)."; fi ;;
    macOS)
        if have_cmd pbcopy; then pass "macOS clipboard provider: pbcopy"
        else fail "pbcopy is missing; restore the macOS system clipboard tools."; fi ;;
    Windows)
        if have_cmd clip.exe clip; then pass "Windows clipboard provider: clip.exe"
        else fail "clip.exe is missing; ensure Windows system tools are on PATH."; fi ;;
    *) warn "Unknown OS; clipboard provider could not be determined" ;;
esac

if [ -r /usr/share/bash-completion/bash_completion ] || [ -r /etc/bash_completion ] || \
   [ -r "${HOMEBREW_PREFIX:-/nonexistent}/etc/profile.d/bash_completion.sh" ]; then
    pass "bash-completion (optional): loader found"
else
    warn "bash-completion is optional; install it for generated command completions"
fi
optional_command "TeX" "install a TeX distribution for VimTeX/texlab" latex pdflatex xelatex lualatex
optional_command "PDF viewer" "install a viewer for VimTeX PDF preview" zathura skim okular evince
optional_command "jai" "install it to use the configured agent sandbox" jai
optional_command "Rust toolchain" "install rustup/cargo to work on Rust projects" rustup cargo rustc
optional_command "Stylua" "Mason normally installs it for Lua formatting" stylua

nvim_config_dir() {
    if [ -n "${XDG_CONFIG_HOME:-}" ]; then
        printf '%s/nvim' "$(printf '%s' "$XDG_CONFIG_HOME" | tr '\134' '/')"
    elif [ "$SYSTEM_OS" = Windows ]; then
        local base="${LOCALAPPDATA:-$HOME/AppData/Local}"
        printf '%s/nvim' "$(printf '%s' "$base" | tr '\134' '/')"
    else printf '%s/nvim' "$HOME/.config"; fi
}

wezterm_config_dir() {
    if [ -n "${XDG_CONFIG_HOME:-}" ]; then
        printf '%s/wezterm' "$(printf '%s' "$XDG_CONFIG_HOME" | tr '\134' '/')"
    else printf '%s/wezterm' "$HOME/.config"; fi
}

normalized_path() {
    local path dir base
    path="$(winpath "$1")"
    case "$path" in
        /*|[A-Za-z]:/*) ;;
        *)
            dir="$(dirname "$path")"; base="$(basename "$path")"
            path="$(cd "$dir" 2>/dev/null && printf '%s/%s' "$PWD" "$base")" || : ;;
    esac
    printf '%s' "$path"
}

check_link() {
    local source="$1" destination="$2" actual expected
    expected="$(normalized_path "$source")"
    if [ ! -L "$destination" ]; then
        if [ -e "$destination" ]; then fail "$destination is not a symlink. Back it up, then re-run init.sh."
        else fail "$destination is missing. Run: bash \"$DOTFILES_PATH/init.sh\""; fi
        return
    fi
    actual="$(normalized_path "$(readlink "$destination")")"
    if [ "$actual" != "$expected" ]; then
        fail "$destination points to $actual, expected $expected. Re-run init.sh after resolving the existing link."
    elif [ ! -e "$destination" ]; then
        fail "$destination is a dangling symlink to $actual. Restore the repository target or re-run init.sh."
    else pass "$destination -> $expected"; fi
}

check_link "$DOTFILES_PATH/shellenv" "$HOME/.shellenv"
check_link "$DOTFILES_PATH/bashrc" "$HOME/.bashrc"
check_link "$DOTFILES_PATH/bashrc_linux" "$HOME/.bashrc_linux"
check_link "$DOTFILES_PATH/bashrc_macos" "$HOME/.bashrc_macos"
check_link "$DOTFILES_PATH/bashrc_windows" "$HOME/.bashrc_windows"
check_link "$DOTFILES_PATH/bash_profile" "$HOME/.bash_profile"
check_link "$DOTFILES_PATH/nvim" "$(nvim_config_dir)"
check_link "$DOTFILES_PATH/wezterm" "$(wezterm_config_dir)"
check_link "$DOTFILES_PATH/bash_aliases" "$HOME/.bash_aliases"
check_link "$DOTFILES_PATH/gitconfig" "$HOME/.gitconfig"

check_tree_links() {
    local source destination
    for source in "$1/"*; do
        [ -e "$source" ] || continue
        destination="$2/$(basename "$source")"
        check_link "$source" "$destination"
    done
}

check_tree_links "$DOTFILES_PATH/claude" "$HOME/.claude"
check_link "$DOTFILES_PATH/shared/agent-instructions.md" "$HOME/.claude/CLAUDE.md"
check_tree_links "$DOTFILES_PATH/codex" "$HOME/.codex"
check_link "$DOTFILES_PATH/shared/agent-instructions.md" "$HOME/.codex/AGENTS.md"
check_tree_links "$DOTFILES_PATH/gemini/antigravity-cli" "$HOME/.gemini/antigravity-cli"
check_link "$DOTFILES_PATH/shared/agent-instructions.md" "$HOME/.gemini/antigravity-cli/AGENTS.md"
check_link "$DOTFILES_PATH/shared/agent-instructions.md" "$HOME/.gemini/GEMINI.md"

for source in "$DOTFILES_PATH/jai/"*; do
    [ -e "$source" ] || continue
    if [ "$(basename "$source")" = jairc ]; then check_link "$source" "$HOME/.jai/.jairc"
    else check_link "$source" "$HOME/.jai/$(basename "$source")"; fi
done

activate="$HOME/py313/bin/activate"
[ "$SYSTEM_OS" = Windows ] && activate="$HOME/py313/Scripts/activate"
if [ -f "$activate" ]; then pass "Optional Python 3.13 environment: $activate"
else warn "$activate is absent; run init.sh with uv available to create it"; fi

completion_dir="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"
for completion in uv uvx pixi rustup cargo; do
    if have_cmd "$completion"; then
        if [ -s "$completion_dir/$completion" ]; then pass "Generated completion: $completion_dir/$completion"
        else warn "$completion is installed but its generated completion is absent; re-run init.sh"; fi
    fi
done

printf '\nSummary: %d PASS, %d WARN, %d FAIL\n' "$passes" "$warnings" "$failures"
if [ "$failures" -gt 0 ]; then
    printf 'Run bash "%s/init.sh" to repair required links; see README.md for dependency installation.\n' "$DOTFILES_PATH"
    exit 1
fi

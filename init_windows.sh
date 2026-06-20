# Windows-specific install logic, sourced by init.sh when SYSTEM_OS=Windows.
# Overrides defaults defined in init.sh; runs before the setup steps.

# Make `ln -s` create real symlinks instead of silently copying (the default).
# nativestrict fails loudly rather than degrading to a copy if symlinks can't
# be created -- that needs Developer Mode on, or an elevated shell (the
# SeCreateSymbolicLinkPrivilege).
export MSYS=winsymlinks:nativestrict

# Install tools via a Windows package manager instead of the *nix curl|sh
# scripts. Prefer winget, fall back to scoop, else tell the user.
install_tools() {
    if command -v starship >/dev/null 2>&1 && command -v uv >/dev/null 2>&1; then
        echo "starship and uv already installed"
        return
    fi

    # Each install is trailed by `|| echo` so a failed package install warns
    # instead of aborting init under set -e -- the symlinks are the point; an
    # optional tool is best-effort. The `command -v` guard short-circuits before
    # the installer when the tool is already present, so neither runs then.
    if command -v winget >/dev/null 2>&1; then
        command -v starship >/dev/null 2>&1 || \
            winget install --id Starship.Starship -e --silent \
                --accept-package-agreements --accept-source-agreements || \
            echo "Warning: starship install via winget failed; skipping." >&2
        command -v uv >/dev/null 2>&1 || \
            winget install --id astral-sh.uv -e --silent \
                --accept-package-agreements --accept-source-agreements || \
            echo "Warning: uv install via winget failed; skipping." >&2
    elif command -v scoop >/dev/null 2>&1; then
        command -v starship >/dev/null 2>&1 || scoop install starship || \
            echo "Warning: starship install via scoop failed; skipping." >&2
        command -v uv >/dev/null 2>&1 || scoop install uv || \
            echo "Warning: uv install via scoop failed; skipping." >&2
    else
        echo "Neither winget nor scoop found; install starship and uv manually." >&2
    fi
}

# Surface a tool install_tools just installed for the rest of this run. winget
# and scoop add it to the *persisted* user PATH, which this already-running shell
# doesn't see, so command -v would miss uv and setup_pyenv would skip. Rather
# than re-read the registry, point PATH at the package managers' shim dirs:
# winget aliases portable installs (uv) into %LOCALAPPDATA%\Microsoft\WinGet\Links;
# scoop shims into ~/scoop/shims. path_prepend (from os_env) no-ops on a missing
# dir, so listing both is safe whichever manager ran; winpath normalizes the
# LOCALAPPDATA backslashes to the C:/... form bashrc already uses on PATH.
# (starship installs elsewhere, but nothing later in init needs it.)
ensure_tools_on_path() {
    local localappdata="${LOCALAPPDATA:-$HOME/AppData/Local}"
    path_prepend "$(winpath "$localappdata/Microsoft/WinGet/Links")"
    path_prepend "$HOME/scoop/shims"
}

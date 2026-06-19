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

    if command -v winget >/dev/null 2>&1; then
        command -v starship >/dev/null 2>&1 || \
            winget install --id Starship.Starship -e --silent \
                --accept-package-agreements --accept-source-agreements
        command -v uv >/dev/null 2>&1 || \
            winget install --id astral-sh.uv -e --silent \
                --accept-package-agreements --accept-source-agreements
    elif command -v scoop >/dev/null 2>&1; then
        command -v starship >/dev/null 2>&1 || scoop install starship
        command -v uv >/dev/null 2>&1 || scoop install uv
    else
        echo "Neither winget nor scoop found; install starship and uv manually." >&2
    fi
}

#!/usr/bin/env bash

# Read-only repository smoke checks. Temporary application state is removed on exit.

set -u

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
cd "$ROOT" || exit 1

passes=0
failures=0
skips=0
tmp_dir=

cleanup() {
	if [[ -n $tmp_dir ]]; then
		rm -rf -- "$tmp_dir"
	fi
}
trap cleanup EXIT HUP INT TERM

pass() {
	printf 'PASS  %s\n' "$1"
	passes=$((passes + 1))
}

fail() {
	printf 'FAIL  %s\n' "$1"
	failures=$((failures + 1))
}

skip() {
	printf 'SKIP  %s\n' "$1"
	skips=$((skips + 1))
}

run_quiet() {
	local label=$1
	shift
	local output
	if output=$("$@" 2>&1); then
		pass "$label"
	else
		fail "$label"
		if [[ -n $output ]]; then
			printf '%s\n' "$output" | sed 's/^/      /'
		fi
	fi
}

tracked_files() {
	git ls-files "$@"
}

check_shell() {
	local file failed=0
	while IFS= read -r file; do
		case $file in
			*.sh | bashrc | bashrc_* | bash_aliases | bash_profile | shellenv)
				if ! bash -n "$file"; then
					printf '      invalid shell syntax: %s\n' "$file"
					failed=1
				fi
				;;
		esac
	done < <(tracked_files)
	if ((failed)); then fail "shell syntax"; else pass "shell syntax"; fi
}

check_lua() {
	local file output failed=0
	if ! command -v nvim >/dev/null 2>&1; then
		skip "Lua syntax (Neovim unavailable)"
		return
	fi
	while IFS= read -r file; do
		if ! output=$(CHECK_FILE="$ROOT/$file" nvim --clean --headless -u NONE \
			-c 'lua local chunk, message = loadfile(vim.env.CHECK_FILE); if not chunk then io.stderr:write(message .. "\n"); vim.cmd("cquit") end' \
			-c 'quitall!' 2>&1); then
			printf '      invalid Lua syntax: %s\n' "$file"
			[[ -n $output ]] && printf '%s\n' "$output" | sed 's/^/      /'
			failed=1
		fi
	done < <(tracked_files '*.lua')
	if ((failed)); then fail "Lua syntax"; else pass "Lua syntax"; fi
}

check_json() {
	local file output failed=0
	if ! command -v python3 >/dev/null 2>&1 || ! python3 -c 'import json' >/dev/null 2>&1; then
		skip "JSON syntax (Python json unavailable)"
		return
	fi
	while IFS= read -r file; do
		if ! output=$(python3 -m json.tool "$file" 2>&1 >/dev/null); then
			printf '      invalid JSON: %s\n' "$file"
			[[ -n $output ]] && printf '%s\n' "$output" | sed 's/^/      /'
			failed=1
		fi
	done < <(tracked_files '*.json')
	if ((failed)); then fail "JSON syntax"; else pass "JSON syntax"; fi
}

check_toml() {
	local file output failed=0
	if ! command -v python3 >/dev/null 2>&1 || ! python3 -c 'import tomllib' >/dev/null 2>&1; then
		skip "TOML syntax (Python tomllib unavailable)"
		return
	fi
	while IFS= read -r file; do
		if ! output=$(python3 -c 'import pathlib, sys, tomllib; tomllib.loads(pathlib.Path(sys.argv[1]).read_text())' "$file" 2>&1); then
			printf '      invalid TOML: %s\n' "$file"
			[[ -n $output ]] && printf '%s\n' "$output" | sed 's/^/      /'
			failed=1
		fi
	done < <(tracked_files '*.toml')
	if ((failed)); then fail "TOML syntax"; else pass "TOML syntax"; fi
}

check_prompt_parity() {
	local name failed=0
	local names
	names=$({
		tracked_files 'claude/commands/*.md' | sed -n 's#^claude/commands/\([^/]*\)\.md$#\1#p'
		tracked_files 'codex/prompts/*.md' | sed -n 's#^codex/prompts/\([^/]*\)\.md$#\1#p'
		tracked_files 'gemini/antigravity-cli/skills/*/SKILL.md' | sed -n 's#^gemini/antigravity-cli/skills/\([^/]*\)/SKILL\.md$#\1#p'
	} | sort -u)
	while IFS= read -r name; do
		[[ -z $name ]] && continue
		for file in "claude/commands/$name.md" "codex/prompts/$name.md" \
			"gemini/antigravity-cli/skills/$name/SKILL.md"; do
			if ! git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
				printf '      missing prompt-family member: %s\n' "$file"
				failed=1
			fi
		done
	done <<< "$names"
	if ((failed)); then fail "mirrored prompt families"; else pass "mirrored prompt families"; fi
}

check_whitelists() {
	local root path kind line member failed=0 member_failed
	for root in claude codex gemini/antigravity-cli; do
		while IFS= read -r path; do
			kind=${path#"$root"/}
			kind=${kind%%/*}
			if [[ $path == "$root/$kind" ]]; then
				line="!$root/$kind"
				if ! grep -Fqx -- "$line" .gitignore; then
					printf '      missing .gitignore whitelist: %s\n' "$line"
					failed=1
				fi
			else
				line="!$root/$kind/"
				if ! grep -Fqx -- "$line" .gitignore; then
					printf '      missing .gitignore whitelist: %s\n' "$line"
					failed=1
				fi
				if ! grep -Fqx -- "!$root/$kind/**" .gitignore; then
					member_failed=0
					while IFS= read -r member; do
						if ! grep -Fqx -- "!$member" .gitignore; then
							printf '      missing .gitignore whitelist: !%s (or !%s/**)\n' \
								"$member" "$root/$kind"
							member_failed=1
						fi
					done < <(tracked_files "$root/$kind/**")
					((member_failed)) && failed=1
				fi
			fi
		done < <(tracked_files "$root/**" | awk -F/ -v root="$root" '!seen[$1 FS $2 FS (root ~ /\// ? $3 : "")]++')
	done
	if ((failed)); then fail ".gitignore config whitelists"; else pass ".gitignore config whitelists"; fi
}

ensure_tmp_dir() {
	if [[ -z $tmp_dir ]]; then
		tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-check.XXXXXX" 2>/dev/null) || return 1
	fi
}

check_nvim_load() {
	if ! command -v nvim >/dev/null 2>&1; then
		skip "Neovim config load (Neovim unavailable)"
	elif ! ensure_tmp_dir; then
		skip "Neovim config load (temporary isolation directory unavailable)"
	else
		run_quiet "Neovim core config load" env HOME="$tmp_dir/nvim-home" \
			XDG_CACHE_HOME="$tmp_dir/nvim-cache" XDG_CONFIG_HOME="$tmp_dir/nvim-config" \
			XDG_DATA_HOME="$tmp_dir/nvim-data" XDG_STATE_HOME="$tmp_dir/nvim-state" \
			nvim --clean --headless -u NONE --cmd "set runtimepath^=$ROOT/nvim" \
			-c "lua vim.g.mapleader = ' '; require('edlwang.editor')" -c 'quitall!'
	fi
}

check_wezterm_load() {
	if ! command -v wezterm >/dev/null 2>&1; then
		skip "WezTerm config load (WezTerm unavailable)"
		return
	fi
	if ! wezterm --version >/dev/null 2>&1; then
		skip "WezTerm config load (WezTerm executable cannot run)"
		return
	fi
	if ! ensure_tmp_dir; then
		skip "WezTerm config load (temporary isolation directory unavailable)"
		return
	fi
	mkdir -p "$tmp_dir/wezterm-home" "$tmp_dir/wezterm-cache" \
		"$tmp_dir/wezterm-config" "$tmp_dir/wezterm-data"
	run_quiet "WezTerm config load" env HOME="$tmp_dir/wezterm-home" \
		XDG_CACHE_HOME="$tmp_dir/wezterm-cache" XDG_CONFIG_HOME="$tmp_dir/wezterm-config" \
		XDG_DATA_HOME="$tmp_dir/wezterm-data" wezterm --config-file "$ROOT/wezterm/wezterm.lua" show-keys
}

if ! command -v git >/dev/null 2>&1; then
	fail "Git is required to enumerate tracked files"
else
	check_shell
	check_lua
	check_json
	check_toml
	run_quiet "Git whitespace errors" git diff --check
	check_prompt_parity
	check_whitelists
	check_nvim_load
	check_wezterm_load
fi

printf '\nSummary: %d passed, %d failed, %d skipped\n' "$passes" "$failures" "$skips"
((failures == 0))

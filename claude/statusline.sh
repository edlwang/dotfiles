#!/usr/bin/env bash
# Claude Code status line -> symlinked to ~/.claude/statusline.sh by init.sh and
# wired up via `statusLine` in claude/settings.json.
#
# Mirrors the segment layout of the Codex CLI status line (see the `status_line`
# array in codex/dotfiles.config.toml). Codex renders a rich built-in segment
# bar; Claude Code has no declarative equivalent and only runs a script, so this
# reproduces every Codex segment that Claude exposes on stdin. Segments Codex
# lists but Claude does not carry in its status-line JSON -- the live `reasoning`
# summary, `run-state`, `permissions`, `approval-mode`, and `task-progress` -- are
# omitted. Fields are documented at https://code.claude.com/docs/en/statusline.
set -euo pipefail

input=$(cat)
get() { jq -r "$1" <<<"$input"; }

MODEL=$(get '.model.display_name')
EFFORT=$(get '.effort.level // empty')
DIR=$(get '.workspace.current_dir')
PROJECT=$(get '.workspace.repo.name // empty')
CTX_USED=$(get '.context_window.used_percentage // empty')
CTX_LEFT=$(get '.context_window.remaining_percentage // empty')
FIVE_H=$(get '.rate_limits.five_hour.used_percentage // empty')
WEEK=$(get '.rate_limits.seven_day.used_percentage // empty')

# Colors, to match Codex's status_line_use_colors = true.
DIM=$'\033[2m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
CYAN=$'\033[36m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'
BLUE=$'\033[34m'; MAGENTA=$'\033[35m'

seg=()

# model-with-reasoning
if [ -n "$EFFORT" ]; then
    seg+=("${CYAN}${BOLD}${MODEL}${RESET}${DIM} ${EFFORT}${RESET}")
else
    seg+=("${CYAN}${BOLD}${MODEL}${RESET}")
fi

# current-dir (~ collapses $HOME)
seg+=("${BLUE}${DIR/#$HOME/\~}${RESET}")

# project-name (repo name from the origin remote; absent outside a repo)
[ -n "$PROJECT" ] && seg+=("${MAGENTA}${PROJECT}${RESET}")

# git-branch
if BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null) && [ -n "$BRANCH" ]; then
    seg+=("${GREEN}⎇ ${BRANCH}${RESET}")
fi

# context-used / context-remaining
if [ -n "$CTX_USED" ]; then
    u=${CTX_USED%.*}
    if   [ "$u" -ge 90 ]; then c=$RED
    elif [ "$u" -ge 70 ]; then c=$YELLOW
    else                       c=$GREEN
    fi
    if [ -n "$CTX_LEFT" ]; then
        seg+=("${c}ctx ${u}%${RESET}${DIM} (${CTX_LEFT%.*}% left)${RESET}")
    else
        seg+=("${c}ctx ${u}%${RESET}")
    fi
fi

# five-hour-limit / weekly-limit (Claude.ai Pro/Max only; absent otherwise)
[ -n "$FIVE_H" ] && seg+=("${DIM}5h $(printf '%.0f' "$FIVE_H")%${RESET}")
[ -n "$WEEK" ]   && seg+=("${DIM}7d $(printf '%.0f' "$WEEK")%${RESET}")

# Join segments with a dim middle dot, like Codex's separated bar.
sep="${DIM} · ${RESET}"
out=""
for s in "${seg[@]}"; do
    [ -n "$out" ] && out+="$sep"
    out+="$s"
done
printf '%s\n' "$out"

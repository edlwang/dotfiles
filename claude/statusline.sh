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
# omitted. One segment deliberately goes the *other* way: the rate-limit reset
# time. Claude's JSON carries `resets_at` per window, so the 5h/weekly segments
# below show a reset countdown + clock that Codex cannot -- Codex holds the same
# `resets_at` internally but never renders it (openai/codex#24080), so mirroring
# it there is impossible. Fields are documented at
# https://code.claude.com/docs/en/statusline.
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
FIVE_H_RESET=$(get '.rate_limits.five_hour.resets_at // empty')
WEEK_RESET=$(get '.rate_limits.seven_day.resets_at // empty')

# Colors, to match Codex's status_line_use_colors = true.
DIM=$'\033[2m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
CYAN=$'\033[36m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'
BLUE=$'\033[34m'; MAGENTA=$'\033[35m'

# Render a rate-limit reset as "<countdown> (<clock>)" from a Unix epoch, e.g.
# "2h14m (3:40pm)"; the clock gains a weekday once the reset is a day or more out
# ("3d5h (Wed 5:40am)"). Cross-platform date: GNU takes `-d @<epoch>` with the
# `%-I`/`%P` (no-pad hour, lowercase am/pm) extensions; BSD/macOS takes `-r
# <epoch>` and only the padded `%I`/`%p`. Falls back to countdown-only if neither
# date form parses.
fmt_reset() {
    local epoch=$1 now delta d h m cd dfmt bfmt clock
    now=$(date +%s)
    delta=$(( epoch - now )); (( delta < 0 )) && delta=0
    d=$(( delta / 86400 )); h=$(( delta % 86400 / 3600 )); m=$(( delta % 3600 / 60 ))
    if   (( d > 0 )); then cd="${d}d${h}h"
    elif (( h > 0 )); then cd="${h}h${m}m"
    else                   cd="${m}m"
    fi
    if (( delta >= 86400 )); then dfmt='%a %-I:%M%P'; bfmt='%a %I:%M%p'
    else                          dfmt='%-I:%M%P';    bfmt='%I:%M%p'
    fi
    clock=$(date -d "@$epoch" +"$dfmt" 2>/dev/null) \
        || clock=$(date -r "$epoch" +"$bfmt" 2>/dev/null) \
        || clock=""
    if [ -n "$clock" ]; then printf '%s (%s)' "$cd" "$clock"; else printf '%s' "$cd"; fi
}

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

# five-hour-limit / weekly-limit (Claude.ai Pro/Max only; absent otherwise), each
# with a reset countdown + clock when resets_at is present.
if [ -n "$FIVE_H" ]; then
    s="5h $(printf '%.0f' "$FIVE_H")%"
    [ -n "$FIVE_H_RESET" ] && s+=" ↻ $(fmt_reset "$FIVE_H_RESET")"
    seg+=("${DIM}${s}${RESET}")
fi
if [ -n "$WEEK" ]; then
    s="7d $(printf '%.0f' "$WEEK")%"
    [ -n "$WEEK_RESET" ] && s+=" ↻ $(fmt_reset "$WEEK_RESET")"
    seg+=("${DIM}${s}${RESET}")
fi

# Join segments with a dim middle dot, like Codex's separated bar.
sep="${DIM} · ${RESET}"
out=""
for s in "${seg[@]}"; do
    [ -n "$out" ] && out+="$sep"
    out+="$s"
done
printf '%s\n' "$out"

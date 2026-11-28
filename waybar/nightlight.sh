#!/usr/bin/env bash

log="${SWAYSOCK:-}.wlsunset.log"
pid_file="${SWAYSOCK:-}.wlsunset.pid"

wlsunset_running() {
    [[ -n ${SWAYSOCK:-} && -s $log && -s $pid_file ]] &&
        pgrep -u "$UID" -x -F "$pid_file" wlsunset >/dev/null
}

case "${1:-status}" in
    start)
        : "${SWAYSOCK:?Sway socket is required}"
        shift
        exec 2>"$log" || exit 1
        printf '%s\n' "$$" > "$pid_file" || exit 1
        exec wlsunset "$@"
        ;;
    toggle)
        if wlsunset_running; then
            exec pkill -USR1 -u "$UID" -x -F "$pid_file" wlsunset
        fi
        exit 0
        ;;
    status) ;;
    *)
        printf 'Usage: %s [status | toggle | start <wlsunset options>]\n' "$0" >&2
        exit 2
        ;;
esac

if ! wlsunset_running; then
    echo '{"text":"󰖔","class":"off","tooltip":"Night light unavailable"}'
    exit 0
fi

mode=$(grep -E '^(forcing high temperature|forcing low temperature|disabling forced temperature)$' "$log" 2>/dev/null | tail -n 1)

case "$mode" in
    "forcing high temperature")
        echo '{"text":"󰖙","class":"day","tooltip":"Night light: Forced day"}'
        ;;
    "forcing low temperature")
        echo '{"text":"󰖔","class":"night","tooltip":"Night light: Forced night"}'
        ;;
    *)
        echo '{"text":"󰔎","class":"auto","tooltip":"Night light: Automatic"}'
        ;;
esac

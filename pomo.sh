#!/bin/sh
#
# pomo.sh — a tiny, quiet pomodoro timer for macos
#
# usage:
#   ./pomo.sh                  # default: 50/10 × 4 cycles
#   ./pomo.sh 25 5 6           # positional: work/break/cycles
#   ./pomo.sh -w 30 -b 5 -c 3  # flags

# default timings
WORK_MIN=50
BREAK_MIN=10
CYCLES=4

# positional form: ./pomo.sh 50 10 6
if [ -n "$1" ] && echo "$1" | grep -qE '^[0-9]+$'; then
    WORK_MIN="$1"
    [ -n "$2" ] && BREAK_MIN="$2"
    [ -n "$3" ] && CYCLES="$3"
    shift 3 || true
fi

# flag form: -w 30 -b 5 -c 4
while [ -n "${1:-}" ]; do
    case "$1" in
        -w|--work)   WORK_MIN="$2";   shift 2 ;;
        -b|--break)  BREAK_MIN="$2";  shift 2 ;;
        -c|--cycles) CYCLES="$2";     shift 2 ;;
        -h|--help)
            sed -n '1,120p' "$0"
            exit 0 ;;
        *) shift ;;
    esac
done

notify() {
    osascript -e "display notification \"$2\" with title \"$1\"" \
        >/dev/null 2>&1 || true
}

play_ping() {
    [ -x /usr/bin/afplay ] &&
        afplay /System/Library/Sounds/Glass.aiff >/dev/null 2>&1 || true
}

countdown() {
    total="$1"
    label="$2"

    while [ "$total" -ge 0 ]; do
        min=$(( total / 60 ))
        sec=$(( total % 60 ))
        printf "\r%s — %02d:%02d  " "$label" "$min" "$sec"

        [ "$total" -eq 0 ] && { printf "\n"; break; }

        sleep 1
        total=$(( total - 1 ))
    done
}

echo "pomo: work=${WORK_MIN}m, break=${BREAK_MIN}m, cycles=${CYCLES}"

trap '
    printf "\nstopped.\n"
    notify "pomo" "stopped by user"
    exit 130
' INT

cycle=1
while [ "$cycle" -le "$CYCLES" ]; do
    notify "work #$cycle" "focus for ${WORK_MIN} minutes"
    play_ping
    countdown $(( WORK_MIN * 60 )) "work  #$cycle"

    play_ping
    notify "break" "take ${BREAK_MIN} minutes"

    countdown $(( BREAK_MIN * 60 )) "break #$cycle"

    play_ping
    notify "back to it" "break over"

    cycle=$(( cycle + 1 ))
    sleep 1
done

notify "pomo" "all ${CYCLES} cycles done — good job"
play_ping
echo "done. all ${CYCLES} cycles finished."

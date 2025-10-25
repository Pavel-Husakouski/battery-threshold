#!/bin/sh
# Read /sys/class/power_supply/BAT0/capacity and
# - if value < LOW_CAPACITY -> threshold to be HIGH_THRESHOLD
# - if value > HIGH_CAPACITY -> threshold to be LOW_THRESHOLD
# - if LOW_CAPACITY <= value <= HIGH_CAPACITY -> do nothing
# Write /sys/class/power_supply/BAT0/charge_control_end_threshold

THRESHOLD=/sys/class/power_supply/BAT0/charge_control_end_threshold
CAPACITY=/sys/class/power_supply/BAT0/capacity
LOGTAG="battery-threshold"
DEBUG=${DEBUG:-0}

LOW_CAPACITY=${LOW_CAPACITY:-60}      # Below this, charge to high threshold
HIGH_CAPACITY=${HIGH_CAPACITY:-70}    # Above this, charge to low threshold
HIGH_THRESHOLD=${HIGH_THRESHOLD:-100} # Max charge when battery is low
LOW_THRESHOLD=${LOW_THRESHOLD:-50}    # Max charge when battery is high

log_debug() {
  [ "$DEBUG" = "1" ] && /usr/bin/logger -t "$LOGTAG" "[DEBUG] $1"
}

log_info() {
  /usr/bin/logger -t "$LOGTAG" "$1"
}

log_error() {
  /usr/bin/logger -t "$LOGTAG" "[ERROR] $1"
}

if [ ! -r "$THRESHOLD" ] || [ ! -w "$THRESHOLD" ]; then
  log_error "file $THRESHOLD not found, or unreadable or unwritable"
  exit 1
fi

if [ ! -r "$CAPACITY" ]; then
  log_error "file $CAPACITY not found or unreadable"
  exit 1
fi


val="$(/bin/cat "$CAPACITY" 2>/dev/null | tr -d '[:space:]')"

case "$val" in
  ''|*[!0-9]*)
    log_error "unexpected value '$val' in $CAPACITY"
    exit 2
    ;;
esac

if [ "$val" -lt $LOW_CAPACITY ]; then
  new=$HIGH_THRESHOLD
  log_debug "Capacity $val < $LOW_CAPACITY, setting threshold to $new"
elif [ "$val" -gt $HIGH_CAPACITY ]; then
  new=$LOW_THRESHOLD
  log_debug "Capacity $val > $HIGH_CAPACITY, setting threshold to $new"
else
  log_debug "Capacity $val between $LOW_CAPACITY and $HIGH_CAPACITY: no change needed"
  exit 0
fi

current="$(/bin/cat "$THRESHOLD" 2>/dev/null | tr -d '[:space:]')"
if [ "$current" = "$new" ]; then
  log_debug "Threshold already $new: no change needed"
  exit 0
fi

if /bin/printf '%s' "$new" > "$THRESHOLD" 2>/dev/null; then
  log_info "changed threshold from $current to $new (capacity: $val%)"
  exit 0
fi

log_error "failed to write $new to $THRESHOLD"
exit 3


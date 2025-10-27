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
AC_ONLINE=/sys/class/power_supply/ADP0/online

LOW_CAPACITY=${LOW_CAPACITY:-60}      # Below this, charge to high threshold
HIGH_CAPACITY=${HIGH_CAPACITY:-70}    # Above this, charge to low threshold
HIGH_THRESHOLD=${HIGH_THRESHOLD:-100} # Max charge when battery is low
LOW_THRESHOLD=${LOW_THRESHOLD:-50}    # Max charge when battery is high

# Exit code mapping (unique codes starting at 1):
# 1 = THRESHOLD file not found, or unreadable or unwritable
# 2 = CAPACITY file not found or unreadable
# 3 = unexpected (non-numeric) value in CAPACITY
# 4 = failed to write new threshold
# 5 = unknown AC state value in $AC_ONLINE

log_debug() {
  [ "$DEBUG" = "1" ] && /usr/bin/logger -t "$LOGTAG" "[DEBUG] $1"
}

log_info() {
  /usr/bin/logger -t "$LOGTAG" "$1"
}

log_error() {
  /usr/bin/logger -t "$LOGTAG" "[ERROR] $1"
}

# Exit early when running on battery (AC online file reports 0)
if [ -r "$AC_ONLINE" ]; then
  ac="$(/bin/cat "$AC_ONLINE" 2>/dev/null | tr -d '[:space:]')"
  case "$ac" in
    0)
      log_debug "AC offline (on battery): skipping"
      exit 0
      ;;
    1)
      ;; # AC online, continue
    *)
      log_info "unknown AC state '$ac' in $AC_ONLINE"
      exit 5
      ;;
  esac
fi

if [ ! -r "$THRESHOLD" ] || [ ! -w "$THRESHOLD" ]; then
  log_error "file $THRESHOLD not found, or unreadable or unwritable"
  exit 1
fi

if [ ! -r "$CAPACITY" ]; then
  log_error "file $CAPACITY not found or unreadable"
  exit 2
fi


val="$(/bin/cat "$CAPACITY" 2>/dev/null | tr -d '[:space:]')"

case "$val" in
  ''|*[!0-9]*)
    log_error "unexpected value '$val' in $CAPACITY"
    exit 3
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
exit 4

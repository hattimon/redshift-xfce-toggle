#!/bin/bash

LOCKFILE="/tmp/redshift_status.lock"
CONFIG_FILE="$HOME/.config/redshift/redshift.conf"
ICON_ON="$HOME/.local/share/icons/redshift-on.png"
ICON_OFF="$HOME/.local/share/icons/redshift-off.png"

# Functions
turn_on() {
  redshift -c "$CONFIG_FILE" &
  sleep 1  # Wait for Redshift to start
  echo "on" > "$LOCKFILE"
  notify-send -i "$ICON_ON" "Redshift enabled"
  # Manual icon update (requires correct plugin ID)
  # xfconf-query -c xfce4-panel -p /plugins/plugin-X/icon -s "$ICON_ON" 2>/dev/null
  # xfce4-panel -r 2>/dev/null || true
}

turn_off() {
  pkill redshift || true
  sleep 1  # Wait for Redshift to stop
  echo "off" > "$LOCKFILE"
  notify-send -i "$ICON_OFF" "Redshift disabled"
  # Manual icon update (requires correct plugin ID)
  # xfconf-query -c xfce4-panel -p /plugins/plugin-X/icon -s "$ICON_OFF" 2>/dev/null
  # xfce4-panel -r 2>/dev/null || true
}

set_temp() {
  TEMP=$1
  sed -i "s/temp-day=.*/temp-day=$TEMP/" "$CONFIG_FILE"
  sed -i "s/temp-night=.*/temp-night=$((TEMP-1000))/" "$CONFIG_FILE"
  if [ "$(cat "$LOCKFILE" 2>/dev/null)" = "on" ]; then
    pkill redshift || true
    sleep 1
    redshift -c "$CONFIG_FILE" &
    notify-send -i "$ICON_ON" "Redshift: temperature set to $TEMP K"
    # Manual icon update (requires correct plugin ID)
    # xfconf-query -c xfce4-panel -p /plugins/plugin-X/icon -s "$ICON_ON" 2>/dev/null
    # xfce4-panel -r 2>/dev/null || true
  fi
}

# Context menu with yad
if [ "$1" = "--menu" ]; then
  if ! command -v yad >/dev/null 2>&1; then
    notify-send "Error" "yad package not installed. Install it: sudo apt install yad"
    exit 1
  fi
  ACTION=$(yad --title="Redshift" --window-icon="$ICON_ON" \
    --text="Choose option:" --list --no-headers --print-output --column="Option" \
    "Enable" "Disable" "Temperature 4500K" "Temperature 5500K" "Temperature 6500K" --width=200 --height=200 2>/dev/null | cut -d'|' -f1)
  echo "Processed yad output: '$ACTION'"  # Debugging
  if [ -z "$ACTION" ]; then
    notify-send "Error" "No option selected or output is empty"
  else
    case "$ACTION" in
      "Enable") turn_on ;;
      "Disable") turn_off ;;
      "Temperature 4500K") set_temp 4500 ;;
      "Temperature 5500K") set_temp 5500 ;;
      "Temperature 6500K") set_temp 6500 ;;
      *) notify-send "Error" "Unknown option: '$ACTION'" ;;
    esac
  fi
  exit 0
fi

# Standard toggle
if [ -f "$LOCKFILE" ]; then
  STATUS=$(cat "$LOCKFILE")
  if [ "$STATUS" = "on" ]; then
    turn_off
  else
    turn_on
  fi
else
  turn_on
fi

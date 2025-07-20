#!/bin/bash

LOCKFILE="/tmp/redshift_status.lock"
CONFIG_FILE="$HOME/.config/redshift/redshift.conf"

# Funkcje
turn_on() {
  redshift -c "$CONFIG_FILE" &
  echo "on" > "$LOCKFILE"
  notify-send -i "$HOME/.local/share/icons/redshift-on.png" "Redshift włączony"
}

turn_off() {
  pkill redshift || true
  echo "off" > "$LOCKFILE"
  notify-send -i "$HOME/.local/share/icons/redshift-off.png" "Redshift wyłączony"
}

set_temp() {
  TEMP=$1
  sed -i "s/temp-day=.*/temp-day=$TEMP/" "$CONFIG_FILE"
  sed -i "s/temp-night=.*/temp-night=$((TEMP-1000))/" "$CONFIG_FILE"
  if [ "$(cat "$LOCKFILE" 2>/dev/null)" = "on" ]; then
    pkill redshift || true
    redshift -c "$CONFIG_FILE" &
    notify-send -i "$HOME/.local/share/icons/redshift-on.png" "Redshift: ustawiono temperaturę $TEMP K"
  fi
}

# Menu kontekstowe z yad
if [ "$1" = "--menu" ]; then
  ACTION=$(yad --title="Redshift" --window-icon="$HOME/.local/share/icons/redshift-on.png" \
    --text="Wybierz opcję:" --form --separator="" \
    --field=":CB" "Włącz!Wyłącz!Temperatura 4500K!Temperatura 5500K!Temperatura 6500K")
  case "$ACTION" in
    "Włącz") turn_on ;;
    "Wyłącz") turn_off ;;
    "Temperatura 4500K") set_temp 4500 ;;
    "Temperatura 5500K") set_temp 5500 ;;
    "Temperatura 6500K") set_temp 6500 ;;
  esac
  exit 0
fi

# Standardowe przełączanie
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
#!/bin/bash

LOCKFILE="/tmp/redshift_status.lock"
CONFIG_FILE="$HOME/.config/redshift/redshift.conf"
ICON_ON="$HOME/.local/share/icons/redshift-on.png"
ICON_OFF="$HOME/.local/share/icons/redshift-off.png"

# Funkcje
turn_on() {
  redshift -c "$CONFIG_FILE" &
  echo "on" > "$LOCKFILE"
  notify-send -i "$ICON_ON" "Redshift włączony"
  # Aktualizacja ikony w panelu XFCE
  PANEL_PLUGIN=$(xfce4-panel --list | grep -n launcher | grep redshift-toggle.desktop | cut -d: -f1)
  if [ -n "$PANEL_PLUGIN" ]; then
    xfconf-query -c xfce4-panel -p /plugins/plugin-$PANEL_PLUGIN/icon -s "$ICON_ON" 2>/dev/null
  fi
}

turn_off() {
  pkill redshift || true
  echo "off" > "$LOCKFILE"
  notify-send -i "$ICON_OFF" "Redshift wyłączony"
  # Aktualizacja ikony w panelu XFCE
  PANEL_PLUGIN=$(xfce4-panel --list | grep -n launcher | grep redshift-toggle.desktop | cut -d: -f1)
  if [ -n "$PANEL_PLUGIN" ]; then
    xfconf-query -c xfce4-panel -p /plugins/plugin-$PANEL_PLUGIN/icon -s "$ICON_OFF" 2>/dev/null
  fi
}

set_temp() {
  TEMP=$1
  sed -i "s/temp-day=.*/temp-day=$TEMP/" "$CONFIG_FILE"
  sed -i "s/temp-night=.*/temp-night=$((TEMP-1000))/" "$CONFIG_FILE"
  # Automatyczne włączenie Redshift, jeśli jest wyłączony
  if [ "$(cat "$LOCKFILE" 2>/dev/null)" != "on" ]; then
    turn_on
  else
    pkill redshift || true
    redshift -c "$CONFIG_FILE" &
    notify-send -i "$ICON_ON" "Redshift: ustawiono temperaturę $TEMP K"
  fi
}

# Menu kontekstowe z yad
if [ "$1" = "--menu" ]; then
  if ! command -v yad >/dev/null 2>&1; then
    notify-send "Błąd" "Pakiet yad nie jest zainstalowany. Zainstaluj go: sudo apt install yad"
    exit 1
  fi
  ACTION=$(yad --title="Redshift" --window-icon="$ICON_ON" \
    --text="Wybierz opcję:" --list --no-headers --column="Opcja" \
    "Włącz" "Wyłącz" "Temperatura 4500K" "Temperatura 5500K" "Temperatura 6500K" 2>/dev/null)
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

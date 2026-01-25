#!/bin/bash
# Redshift XFCE Toggle - FULLY WORKING VERSION

RED_CONF="$HOME/.config/redshift/redshift.conf"

# Create default config if not exists
if [ ! -f "$RED_CONF" ]; then
    mkdir -p "$(dirname "$RED_CONF")"
    cat > "$RED_CONF" << EOF
[redshift]
temp-day=6500
temp-night=3000
transition=1
location-provider=manual
lat=52.2297
lon=21.0122
EOF
fi

# Kill existing redshift process
kill_redshift() {
    pkill -9 redshift 2>/dev/null || true
    sleep 0.3
}

# Start redshift with given temperature
start_redshift() {
    local TEMP=$1
    kill_redshift
    # Update config with new temperature
    sed -i "s/temp-night=[0-9]*/temp-night=$TEMP/" "$RED_CONF"
    sleep 0.2
    # Start with explicit temperature
    redshift -l 52.2297:21.0122 -t 6500:$TEMP &
    sleep 0.5
}

# Check if redshift is running
is_running() {
    pgrep -f "redshift" >/dev/null 2>&1
}

# Show menu with YAD
CHOICE=$(yad \
    --title="🌙 Redshift Control" \
    --width=250 \
    --height=280 \
    --center \
    --list \
    --column="Action" \
    --hide-column=1 \
    --column="Description" \
    "1" "🔴 WŁĄCZ (Turn ON)" \
    "2" "⚫ WYŁĄCZ (Turn OFF)" \
    "3" "🔥 Temperatura 3000K" \
    "4" "🌅 Temperatura 4500K" \
    "5" "❄️  Temperatura 6500K" \
    --button=Cancel:1 \
    --button=OK:0 \
    2>/dev/null)

RESULT=$?

# Handle selection
if [ $RESULT -eq 0 ]; then
    case "$CHOICE" in
        1)
            start_redshift 3000
            notify-send "Redshift" "🔴 WŁĄCZONY (ON)" -t 2000 2>/dev/null || true
            ;;
        2)
            kill_redshift
            notify-send "Redshift" "⚫ WYŁĄCZONY (OFF)" -t 2000 2>/dev/null || true
            ;;
        3)
            start_redshift 3000
            notify-send "Redshift" "🔥 3000K" -t 2000 2>/dev/null || true
            ;;
        4)
            start_redshift 4500
            notify-send "Redshift" "🌅 4500K" -t 2000 2>/dev/null || true
            ;;
        5)
            start_redshift 6500
            notify-send "Redshift" "❄️ 6500K" -t 2000 2>/dev/null || true
            ;;
    esac
fi

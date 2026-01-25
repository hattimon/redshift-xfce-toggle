#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}🌍 Wybierz język / Select language:${NC}"
echo "1) Polski"
echo "2) English"
read -p "Wybierz (1-2) / Choose (1-2) [1]: " LANG_CHOICE

case $LANG_CHOICE in
    1|"" ) LANG="pl" ;;
    2 ) LANG="en" ;;
    * ) LANG="pl" ;;
esac

if [ "$LANG" = "pl" ]; then
    TITLE="🚀 Redshift XFCE Toggle - Instalacja"
    CHECK_DEPS="Sprawdzanie zależności..."
    INSTALL_SCRIPT="Instalacja redshift-toggle..."
    CREATE_DIRS="Tworzenie katalogów..."
    VERIFY="Weryfikacja..."
    COMPLETE="INSTALACJA UKOŃCZONA!"
    HAPPY_CODING="Miłej pracy! 🌙"
else
    TITLE="🚀 Redshift XFCE Toggle - Installation"
    CHECK_DEPS="Checking dependencies..."
    INSTALL_SCRIPT="Installing redshift-toggle..."
    CREATE_DIRS="Creating directories..."
    VERIFY="Verification..."
    COMPLETE="INSTALLATION COMPLETE!"
    HAPPY_CODING="Happy coding! 🌙"
fi

echo -e "${YELLOW}${TITLE}${NC}\n"

echo -e "${GREEN}[*] ${CHECK_DEPS}${NC}"
command -v redshift >/dev/null 2>&1 || sudo apt update && sudo apt install -y redshift
command -v yad >/dev/null 2>&1 || sudo apt install -y yad

echo -e "${GREEN}[*] ${CREATE_DIRS}${NC}"
mkdir -p ~/.local/bin ~/.local/share/applications ~/.config/autostart

echo -e "${GREEN}[*] ${INSTALL_SCRIPT}${NC}"
cat > ~/.local/bin/redshift-toggle << 'REDTOGGLE_SCRIPT'
#!/bin/bash
# Redshift XFCE Toggle - FIXED VERSION FOR MENU LAUNCHER

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"
export HOME="${HOME:=$(echo ~)}"

if [ -z "$DISPLAY" ]; then
    DISPLAY=$(ps -u "$USER" -o cmd= | grep -oP 'DISPLAY=\K[^ ]+' | head -1)
    [ -z "$DISPLAY" ] && DISPLAY=":0"
    export DISPLAY
fi

export XAUTHORITY="${XAUTHORITY:=$HOME/.Xauthority}"

RED_CONF="$HOME/.config/redshift/redshift.conf"

if [ ! -f "$RED_CONF" ]; then
    mkdir -p "$(dirname "$RED_CONF")"
    cat > "$RED_CONF" << 'CONF'
[redshift]
temp-day=6500
temp-night=3000
transition=1
location-provider=manual
lat=52.2297
lon=21.0122
CONF
fi

toggle_redshift() {
    if pgrep redshift >/dev/null 2>&1; then
        pkill -9 redshift 2>/dev/null || true
        sleep 0.3
        notify-send -u critical "Redshift" "⚫ WYŁĄCZONY / OFF" -t 2000 2>/dev/null || true
    else
        redshift -l 52.2297:21.0122 &
        sleep 1
        notify-send -u normal "Redshift" "🔴 WŁĄCZONY / ON" -t 2000 2>/dev/null || true
    fi
}

set_temp() {
    local TEMP=$1
    sed -i "s/temp-night=[0-9]*/temp-night=$TEMP/" "$RED_CONF"
    pkill -9 redshift 2>/dev/null || true
    sleep 0.5
    redshift -l 52.2297:21.0122 &
    sleep 1
    notify-send "Redshift" "🌅 $TEMP K" -t 2000 2>/dev/null || true
}

yad --title="🌙 Redshift Control / Kontrola" \
    --window-icon=redshift \
    --width=300 --height=200 \
    --buttons-layout=center \
    --button="🔴 WŁĄCZ (ON)"!"#FF0000":"1" \
    --button="⚫ WYŁĄCZ (OFF)"!"#808080":"2" \
    --button="🔥 3000K"!"#FF6600":"3" \
    --button="🌅 4500K"!"#FFD700":"4" \
    --button="❄️  6500K"!"#0099FF":"5" 2>/dev/null

RESULT=$?

case $RESULT in
    1) toggle_redshift ;;
    2) pkill -9 redshift 2>/dev/null || true; notify-send -u critical "Redshift" "⚫ WYŁĄCZONY / OFF" -t 2000 2>/dev/null || true ;;
    3) set_temp 3000 ;;
    4) set_temp 4500 ;;
    5) set_temp 6500 ;;
esac
REDTOGGLE_SCRIPT

chmod +x ~/.local/bin/redshift-toggle

cat > ~/.local/share/applications/redshift-toggle.desktop << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=🌙 Redshift Toggle
Comment=Control screen light intensity / Kontrola światła ekranu
Icon=redshift
Exec=bash -i -c '~/.local/bin/redshift-toggle'
Terminal=false
Categories=Utility;System;
StartupNotify=true
X-XFCE-Exec-Terminal=false
DESKTOP

cat > ~/.config/autostart/redshift-autoenable.desktop << 'AUTOSTART'
[Desktop Entry]
Type=Application
Name=Redshift Auto-Enable
Exec=bash -i -c 'sleep 3 && /usr/bin/redshift -l 52.2297:21.0122 &'
X-XFCE-Autostart=true
NoDisplay=false
AUTOSTART

update-desktop-database ~/.local/share/applications/ 2>/dev/null || true

echo -e "${GREEN}[*] ${VERIFY}${NC}"
[ -f ~/.local/bin/redshift-toggle ] && echo -e "${GREEN}✅ redshift-toggle installed${NC}"
[ -f ~/.local/share/applications/redshift-toggle.desktop ] && echo -e "${GREEN}✅ Desktop entry created${NC}"
[ -f ~/.config/autostart/redshift-autoenable.desktop ] && echo -e "${GREEN}✅ Autostart configured${NC}"

echo -e "\n${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}${COMPLETE}${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📁 Installed files:${NC}"
echo "  • ~/.local/bin/redshift-toggle"
echo "  • ~/.local/share/applications/redshift-toggle.desktop"
echo "  • ~/.config/autostart/redshift-autoenable.desktop"

echo -e "\n${YELLOW}🎨 Features:${NC}"
echo "  • 5 buttons: ON, OFF, 3000K, 4500K, 6500K"
echo "  • Color-coded buttons with icons"
echo "  • Auto-restart redshift on temperature change"
echo "  • Auto-enable on login"
echo "  • Notification feedback"
echo "  • Polish & English support"
echo "  • ✅ FIXED: Works when clicked in menu!"

echo -e "\n${YELLOW}🚀 Usage:${NC}"
if [ "$LANG" = "pl" ]; then
    echo "  1. Otwórz menu: Aplikacje → 🌙 Redshift Toggle"
    echo "  2. Kliknij przycisk aby zmienić ustawienia"
    echo "  3. Redshift uruchomi się automatycznie po zalogowaniu"
else
    echo "  1. Open menu: Applications → 🌙 Redshift Toggle"
    echo "  2. Click button to change settings"
    echo "  3. Redshift will auto-enable on login"
fi

echo -e "\n${YELLOW}🔧 Useful commands:${NC}"
echo "  • Manual run:     ~/.local/bin/redshift-toggle"
echo "  • Enable only:    /usr/bin/redshift -l 52.2297:21.0122 &"
echo "  • Disable:        pkill redshift"
echo "  • Config file:    ~/.config/redshift/redshift.conf"

echo -e "\n${GREEN}${HAPPY_CODING}${NC}\n"

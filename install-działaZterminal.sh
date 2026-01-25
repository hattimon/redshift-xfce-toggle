#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ============================================
# 0. LANGUAGE SELECTION
# ============================================
echo -e "${YELLOW}🌍 Wybierz język / Select language:${NC}"
echo "1) Polski"
echo "2) English"
read -p "Wybierz (1-2) / Choose (1-2) [1]: " LANG_CHOICE

case $LANG_CHOICE in
    1|"" ) LANG="pl" ;;
    2 ) LANG="en" ;;
    * ) LANG="pl" ;;
esac

# POLISH TEXTS
if [ "$LANG" = "pl" ]; then
    TITLE="🚀 Redshift XFCE Toggle - Instalacja"
    CHECK_DEPS="Sprawdzanie zależności..."
    INSTALL_SCRIPT="Instalacja redshift-toggle..."
    CREATE_DIRS="Tworzenie katalogów..."
    VERIFY="Weryfikacja..."
    INSTALLED="✅ Zainstalowane:"
    TEST_MENU="🔧 Test menu:"
    NEXT_STEPS="Następne kroki:"
    COMPLETE="INSTALACJA UKOŃCZONA!"
    HAPPY_CODING="Miłej pracy! 🌙"
else
    TITLE="🚀 Redshift XFCE Toggle - Installation"
    CHECK_DEPS="Checking dependencies..."
    INSTALL_SCRIPT="Installing redshift-toggle..."
    CREATE_DIRS="Creating directories..."
    VERIFY="Verification..."
    INSTALLED="✅ Installed:"
    TEST_MENU="🔧 Test menu:"
    NEXT_STEPS="Next steps:"
    COMPLETE="INSTALLATION COMPLETE!"
    HAPPY_CODING="Happy coding! 🌙"
fi

echo -e "${YELLOW}${TITLE}${NC}\n"

# ============================================
# 1. CHECK DEPENDENCIES
# ============================================
echo -e "${GREEN}[*] ${CHECK_DEPS}${NC}"
command -v redshift >/dev/null 2>&1 || { 
    echo -e "${RED}[!] Redshift not found / nie znaleziony${NC}"
    sudo apt update && sudo apt install -y redshift 
}
command -v yad >/dev/null 2>&1 || { 
    echo -e "${GREEN}[*] Installing yad / Instaluję yad...${NC}"
    sudo apt install -y yad 
}

# ============================================
# 2. CREATE DIRECTORIES
# ============================================
echo -e "${GREEN}[*] ${CREATE_DIRS}${NC}"
mkdir -p ~/.local/bin ~/.local/share/applications ~/.config/autostart

# ============================================
# 3. INSTALL MAIN SCRIPT
# ============================================
echo -e "${GREEN}[*] ${INSTALL_SCRIPT}${NC}"
cat > ~/.local/bin/redshift-toggle << 'REDTOGGLE_SCRIPT'
#!/bin/bash
# Redshift XFCE Toggle - ULTIMATE FIX VERSION

RED_CONF="$HOME/.config/redshift/redshift.conf"

# Default config if not exists
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

# FORCE KILL any existing redshift
pkill redshift 2>/dev/null || true
sleep 0.3

toggle_redshift() {
    if pgrep redshift >/dev/null 2>&1; then
        pkill -9 redshift 2>/dev/null || true
        sleep 0.2
        notify-send -u critical "Redshift" "⚫ WYŁĄCZONY / OFF" -t 2000
        echo "OFF"
    else
        redshift -l 52.2297:21.0122 &
        sleep 1
        if pgrep redshift >/dev/null 2>&1; then
            notify-send -u normal "Redshift" "🔴 WŁĄCZONY / ON" -t 2000
            echo "ON"
        else
            notify-send -u critical "Redshift" "❌ ERROR: Cannot start / Błąd uruchomienia" -t 3000
            echo "FAILED"
        fi
    fi
}

set_temp() {
    local TEMP=$1
    sed -i "s/temp-night=[0-9]*/temp-night=$TEMP/" "$RED_CONF"
    pkill -9 redshift 2>/dev/null || true
    sleep 0.5
    redshift -l 52.2297:21.0122 &
    sleep 1
    if pgrep redshift >/dev/null 2>&1; then
        notify-send "Redshift" "🌅 $TEMP K" -t 2000
        echo "$TEMP OK"
    else
        notify-send -u critical "Redshift" "❌ $TEMP K - ERROR / BŁĄD" -t 3000
        echo "$TEMP FAILED"
    fi
}

# DEBUG: Show current status
echo "=== DEBUG ==="
echo "Redshift PID: $(pgrep redshift 2>/dev/null || echo 'NONE')"
echo "Config: $RED_CONF"
echo ""

# MAIN YAD MENU - BUTTONS WITH PROPER LAYOUT
yad --title="🌙 Redshift Control / Kontrola" \
    --width=160 --height=300 \
    --buttons-layout=center \
    --button="🔴 ON"!"#FF0000":"1" \
    --button="⚫ OFF"!"#808080":"2" \
    --button="🔥 3000K"!"#FF6600":"3" \
    --button="🌅 4500K"!"#FFD700":"4" \
    --button="❄️ 6500K"!"#0099FF":"5"

RESULT=$?

echo "YAD RESULT: $RESULT"

case $RESULT in
    1) toggle_redshift ;;
    2) 
        pkill -9 redshift 2>/dev/null || true
        sleep 0.2
        notify-send -u critical "Redshift" "⚫ WYŁĄCZONY / OFF" -t 2000
        ;;
    3) set_temp 3000 ;;
    4) set_temp 4500 ;;
    5) set_temp 6500 ;;
    *) echo "Cancelled / Anulowano" ;;
esac
REDTOGGLE_SCRIPT

chmod +x ~/.local/bin/redshift-toggle

# ============================================
# 4. CREATE DESKTOP ENTRY
# ============================================
if [ "$LANG" = "pl" ]; then
    DESKTOP_NAME="Redshift Toggle"
    DESKTOP_COMMENT="Kontrola intensywności światła ekranu"
else
    DESKTOP_NAME="Redshift Toggle"
    DESKTOP_COMMENT="Control screen light intensity"
fi

cat > ~/.local/share/applications/redshift-toggle.desktop << DESKTOP_ENTRY
[Desktop Entry]
Type=Application
Name=${DESKTOP_NAME}
Comment=${DESKTOP_COMMENT}
Icon=redshift
Exec=~/.local/bin/redshift-toggle
Terminal=false
Categories=Utility;
StartupNotify=true
DESKTOP_ENTRY

# ============================================
# 5. CREATE AUTOSTART ENTRY
# ============================================
cat > ~/.config/autostart/redshift-autoenable.desktop << AUTOSTART_ENTRY
[Desktop Entry]
Type=Application
Name=Redshift Auto-Enable
Exec=bash -c 'sleep 3 && redshift -l 52.2297:21.0122 &'
X-XFCE-Autostart=true
NoDisplay=false
AUTOSTART_ENTRY

# Update desktop database
update-desktop-database ~/.local/share/applications/ 2>/dev/null || true

# ============================================
# 6. VERIFY INSTALLATION
# ============================================
echo -e "${GREEN}[*] ${VERIFY}${NC}"

if [ -f ~/.local/bin/redshift-toggle ]; then
    echo -e "${GREEN}✅ redshift-toggle installed${NC}"
fi

if [ -f ~/.local/share/applications/redshift-toggle.desktop ]; then
    echo -e "${GREEN}✅ Desktop entry created${NC}"
fi

if [ -f ~/.config/autostart/redshift-autoenable.desktop ]; then
    echo -e "${GREEN}✅ Autostart configured${NC}"
fi

# ============================================
# 7. INSTALLATION SUMMARY
# ============================================
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

echo -e "\n${YELLOW}🚀 Usage:${NC}"
if [ "$LANG" = "pl" ]; then
    echo "  1. Otwórz menu: Aplikacje → Redshift Toggle"
    echo "  2. Kliknij przycisk aby zmienić ustawienia"
    echo "  3. Redshift uruchomi się automatycznie po zalogowaniu"
else
    echo "  1. Open menu: Applications → Redshift Toggle"
    echo "  2. Click button to change settings"
    echo "  3. Redshift will auto-enable on login"
fi

echo -e "\n${YELLOW}🔧 Useful commands:${NC}"
echo "  • Manual run:     ~/.local/bin/redshift-toggle"
echo "  • Enable only:    redshift -l 52.2297:21.0122 &"
echo "  • Disable:        pkill redshift"
echo "  • Config file:    ~/.config/redshift/redshift.conf"

echo -e "\n${GREEN}${HAPPY_CODING}${NC}\n"

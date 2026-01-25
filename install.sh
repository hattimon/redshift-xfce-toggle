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

if [ "$LANG" = "pl" ]; then
    TITLE="🚀 Redshift XFCE Toggle - Instalacja"
    CHECK_DEPS="Sprawdzanie zależności..."
    CREATE_DIRS="Tworzenie katalogów..."
    INSTALL_SCRIPT="Instalacja redshift-toggle..."
    INSTALL_AUTOSTART="Konfiguracja autostartu..."
    VERIFY="Weryfikacja..."
    COMPLETE="INSTALACJA UKOŃCZONA!"
else
    TITLE="🚀 Redshift XFCE Toggle - Installation"
    CHECK_DEPS="Checking dependencies..."
    CREATE_DIRS="Creating directories..."
    INSTALL_SCRIPT="Installing redshift-toggle..."
    INSTALL_AUTOSTART="Configuring autostart..."
    VERIFY="Verification..."
    COMPLETE="INSTALLATION COMPLETE!"
fi

echo -e "${YELLOW}${TITLE}${NC}\n"

# ============================================
# 1. CHECK DEPENDENCIES
# ============================================
echo -e "${GREEN}[*] ${CHECK_DEPS}${NC}"
command -v redshift >/dev/null 2>&1 || { 
    echo -e "${RED}[!] Redshift not found${NC}"
    sudo apt update && sudo apt install -y redshift 
}
command -v yad >/dev/null 2>&1 || { 
    echo -e "${GREEN}[*] Installing yad...${NC}"
    sudo apt install -y yad 
}

# ============================================
# 2. CREATE DIRECTORIES
# ============================================
echo -e "${GREEN}[*] ${CREATE_DIRS}${NC}"
mkdir -p ~/.local/bin ~/.local/share/applications ~/.config/autostart

# ============================================
# 3. INSTALL REDSHIFT CONFIG
# ============================================
echo -e "${GREEN}[*] Creating redshift config...${NC}"
mkdir -p ~/.config/redshift
cat > ~/.config/redshift/redshift.conf << 'EOF'
[redshift]
temp-day=6500
temp-night=3000
transition=1
location-provider=manual

[manual]
lat=52.2297
lon=21.0122
EOF

# ============================================
# 4. INSTALL MAIN SCRIPT (FIXED - NO PKILL ON START)
# ============================================
echo -e "${GREEN}[*] ${INSTALL_SCRIPT}${NC}"
cat > ~/.local/bin/redshift-toggle << 'REDSHIFT_TOGGLE'
#!/bin/bash
# Redshift XFCE Toggle - FIXED VERSION (No pkill on start)

toggle_redshift() {
    if pgrep redshift >/dev/null 2>&1; then
        pkill -9 redshift 2>/dev/null || true
        sleep 0.2
        notify-send "Redshift" "⚫ WYŁĄCZONY / OFF" -t 2000
    else
        redshift &
        sleep 1
        if pgrep redshift >/dev/null 2>&1; then
            notify-send "Redshift" "🔴 WŁĄCZONY / ON" -t 2000
        else
            notify-send -u critical "Redshift" "❌ ERROR" -t 3000
        fi
    fi
}

set_temp() {
    local TEMP=$1
    sed -i "s/temp-night=[0-9]*/temp-night=$TEMP/" ~/.config/redshift/redshift.conf
    pkill -9 redshift 2>/dev/null || true
    sleep 0.5
    redshift &
    sleep 1
    if pgrep redshift >/dev/null 2>&1; then
        notify-send "Redshift" "🌅 $TEMP K" -t 2000
    else
        notify-send -u critical "Redshift" "❌ $TEMP K ERROR" -t 3000
    fi
}

# MAIN YAD MENU - NO KILLING BEFORE MENU
yad --title="🌙 Redshift Control" \
    --width=220 \
    --height=340 \
    --fixed \
    --center \
    --buttons-layout=center \
    --button="🔴 ON"!"#FF0000":1 \
    --button="⚫ OFF"!"#404040":2 \
    --button="🔥 3000K"!"#FF6600":3 \
    --button="🌅 4500K"!"#FFD700":4 \
    --button="❄️ 6500K"!"#0099FF":5 2>/dev/null

RESULT=$?

case $RESULT in
    1) toggle_redshift ;;
    2) 
        pkill -9 redshift 2>/dev/null || true
        notify-send "Redshift" "⚫ OFF" -t 2000
        ;;
    3) set_temp 3000 ;;
    4) set_temp 4500 ;;
    5) set_temp 6500 ;;
esac
REDSHIFT_TOGGLE

chmod +x ~/.local/bin/redshift-toggle

# ============================================
# 5. CREATE DESKTOP ENTRY WITH PROPER DISPLAY
# ============================================
if [ "$LANG" = "pl" ]; then
    DESK_COMMENT="Kontrola intensywności światła ekranu"
else
    DESK_COMMENT="Control screen light intensity"
fi

cat > ~/.local/share/applications/redshift-toggle.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Redshift Toggle
Comment=Control screen light intensity
Icon=redshift
Exec=bash -c 'DISPLAY=${DISPLAY:-:0} ~/.local/bin/redshift-toggle'
Terminal=false
Categories=Utility;
StartupNotify=true
EOF

# ============================================
# 6. CREATE AUTOSTART (ENABLE REDSHIFT ONLY)
# ============================================
echo -e "${GREEN}[*] ${INSTALL_AUTOSTART}${NC}"
cat > ~/.config/autostart/redshift-autoenable.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Redshift Auto-Enable
Comment=Auto-enable Redshift on login
Exec=bash -c 'sleep 3 && redshift &'
Terminal=false
Hidden=false
NoDisplay=false
X-XFCE-Autostart=true
Icon=redshift
EOF

# Update desktop database
update-desktop-database ~/.local/share/applications/ 2>/dev/null || true

# ============================================
# 7. VERIFY INSTALLATION
# ============================================
echo -e "${GREEN}[*] ${VERIFY}${NC}"

echo -e "${GREEN}✅ Files installed:${NC}"
[ -f ~/.local/bin/redshift-toggle ] && echo "  ✓ ~/.local/bin/redshift-toggle"
[ -f ~/.local/share/applications/redshift-toggle.desktop ] && echo "  ✓ Desktop entry"
[ -f ~/.config/autostart/redshift-autoenable.desktop ] && echo "  ✓ Autostart"
[ -f ~/.config/redshift/redshift.conf ] && echo "  ✓ Redshift config"

# ============================================
# 8. INSTALLATION SUMMARY
# ============================================
echo -e "\n${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}${COMPLETE}${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📁 Installed files:${NC}"
echo "  • ~/.local/bin/redshift-toggle"
echo "  • ~/.local/share/applications/redshift-toggle.desktop"
echo "  • ~/.config/autostart/redshift-autoenable.desktop"
echo "  • ~/.config/redshift/redshift.conf"

echo -e "\n${YELLOW}🎨 Features:${NC}"
echo "  ✓ Auto-enable on login (yellow display)"
echo "  ✓ Menu with 5 buttons (ON, OFF, 3000K, 4500K, 6500K)"
echo "  ✓ Instant temperature switching"
echo "  ✓ Notification feedback"
echo "  ✓ Proper config file (lat/lon settings)"

echo -e "\n${YELLOW}🚀 Usage:${NC}"
if [ "$LANG" = "pl" ]; then
    echo "  1. Po restarcie ekran będzie żółty (redshift ON)"
    echo "  2. Otwórz Menu → Redshift Toggle → pojawi się YAD"
    echo "  3. Klikaj przyciski aby zmienić ustawienia"
else
    echo "  1. After restart, screen will be yellow (redshift ON)"
    echo "  2. Open Menu → Redshift Toggle → YAD will appear"
    echo "  3. Click buttons to change settings"
fi

echo -e "\n${YELLOW}🔧 Commands:${NC}"
echo "  Test:      ~/.local/bin/redshift-toggle"
echo "  Disable:   pkill redshift"
echo "  Config:    nano ~/.config/redshift/redshift.conf"
echo "  Logs:      journalctl -xeu redshift"

echo -e "\n${GREEN}Happy coding! 🌙${NC}\n"

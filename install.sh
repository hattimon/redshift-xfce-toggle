#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}🚀 Redshift XFCE Toggle - Auto Installation${NC}\n"

# ============================================
# 1. CHECK DEPENDENCIES
# ============================================
echo -e "${GREEN}[*] Sprawdzanie zależności...${NC}"
command -v redshift >/dev/null 2>&1 || { echo -e "${RED}[!] Redshift nie znaleziony. Instaluję...${NC}"; sudo apt update && sudo apt install -y redshift; }
command -v yad >/dev/null 2>&1 || { echo -e "${GREEN}[*] Instaluję yad...${NC}"; sudo apt install -y yad; }

# ============================================
# 2. CREATE DIRECTORIES
# ============================================
echo -e "${GREEN}[*] Tworzenie katalogów...${NC}"
mkdir -p ~/.local/bin ~/.local/share/applications ~/.config/autostart

# ============================================
# 3. INSTALL MAIN SCRIPT
# ============================================
echo -e "${GREEN}[*] Instalacja redshift-toggle...${NC}"
cat > ~/.local/bin/redshift-toggle << 'REDTOGGLE_SCRIPT'
#!/bin/bash
# Redshift XFCE Toggle - Menu kontekstowe

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

; Use manual lat/lon
lat=52.2297
lon=21.0122
EOF
fi

toggle_redshift() {
    if pgrep redshift >/dev/null 2>&1; then
        pkill redshift
        notify-send "Redshift" "Wyłączony" -t 2000
    else
        redshift &
        notify-send "Redshift" "Włączony" -t 2000
    fi
}

set_temp() {
    TEMP=$1
    sed -i "s/temp-night=[0-9]*/temp-night=$TEMP/" "$RED_CONF"
    pkill redshift
    redshift &
    notify-send "Redshift" "Temperatura: ${TEMP}K" -t 2000
}

yad --title="🌙 Redshift Toggle" \
    --text="Redshift Controls" \
    --width=300 --height=250 \
    --buttons-layout=edge \
    --button="🔥 3000K:3" --button="🌅 4500K:2" --button="❄️ 6500K:1" \
    --button="🌙 Toggle:0" --button="❌ Zamknij:1"

case $? in
    0) toggle_redshift ;;
    1) set_temp 3000 ;;
    2) set_temp 4500 ;;
    3) set_temp 6500 ;;
esac
REDTOGGLE_SCRIPT

chmod +x ~/.local/bin/redshift-toggle

# ============================================
# 4. DESKTOP ENTRY
# ============================================
echo -e "${GREEN}[*] Tworzenie wpisu menu...${NC}"
cat > ~/.local/share/applications/redshift-toggle.desktop << 'DESKTOP_ENTRY'
[Desktop Entry]
Name=Redshift Toggle
Comment=Redshift ON/OFF + Temperature
Exec=/home/%u/.local/bin/redshift-toggle
Icon=preferences-desktop-display
Terminal=false
Type=Application
Categories=Utility;
DESKTOP_ENTRY

update-desktop-database ~/.local/share/applications/

# ============================================
# 5. XFCE PANEL LAUNCHER
# ============================================
echo -e "${GREEN}[*] Dodawanie do panelu XFCE...${NC}"
cat > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml << 'PANEL_XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="3"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
  </property>
  <property name="panel-1" type="array">
    <value type="string" value="launcher"/>
    <value type="int" value="0"/>
    <value type="string" value="redshift-toggle"/>
    <value type="string" value="/home/%u/.local/share/applications/redshift-toggle.desktop"/>
  </property>
</channel>
PANEL_XML

# ============================================
# 6. AUTOSTART REDSHIFT
# ============================================
echo -e "${GREEN}[*] Autostart Redshift...${NC}"
cat > ~/.config/autostart/redshift.desktop << 'AUTOSTART'
[Desktop Entry]
Name=Redshift
Exec=redshift -l 52.2297:21.0122 &
Type=Application
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Comment=Redshift screen temperature adjustment
AUTOSTART

# ============================================
# 7. VERIFY INSTALLATION
# ============================================
echo -e "${GREEN}📊 Weryfikacja...${NC}"
sleep 1

echo -e "\n${YELLOW}✅ Installed:${NC}"
ls -la ~/.local/bin/redshift-toggle
echo "  → ~/.local/share/applications/redshift-toggle.desktop"
echo "  → ~/.config/autostart/redshift.desktop"

echo -e "\n${YELLOW}🔧 Test menu:${NC}"
echo "  → Menu Aplikacje → Redshift Toggle"
echo "  → Lub dodaj launcher do panelu XFCE"

echo -e "\n${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}✅ INSTALACJA UKOŃCZONA!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}\n"

echo -e "${YELLOW}🚀 Następne kroki:${NC}"
echo "  1. Restart XFCE panel: xfdesktop --reload"
echo "  2. Menu → Redshift Toggle"
echo "  3. Right-click panel → Panel → Dodaj nowe elementy → Launcher → redshift-toggle.desktop"
echo "  4. Right-click launcher → Preferencje → Ikona: preferences-desktop-display"

echo -e "\n${GREEN}Happy coding! 🌙${NC}"

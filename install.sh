#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Adres repozytorium GitHub
REPO_URL="https://raw.githubusercontent.com/hattimon/redshift-xfce-toggle/main"

# Funkcje
log() { echo -e "${GREEN}[*] $1${NC}"; }
error() { echo -e "${RED}[✗] $1${NC}"; exit 1; }

# PATH
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc 2>/dev/null || true

# 🔍 Internet
log "Checking internet..."
ping -c 1 archive.ubuntu.com &>/dev/null || error "No internet."

# 🔍 Test repo (wszystkie pliki)
log "Testing repository files..."
FILES=("redshift-on.png" "redshift-off.png" "redshift-toggle.sh" "redshift-toggle.desktop")
for file in "${FILES[@]}"; do
  if ! curl -s -f -I -o /dev/null "$REPO_URL/$file"; then
    error "File missing: $file. Check GitHub repo."
  fi
done

# 🔍 Pakiety
log "Checking packages..."
if ! command -v redshift >/dev/null 2>&1; then
  log "Installing packages..."
  sudo apt update || log "Repo warning, continue..."
  sudo apt install -y redshift curl jq yad xfce4-settings || error "Packages failed."
fi

# 🌍 Lokalizacja
echo
echo "🌍 Location (Latin names):"
read -p "Country (Poland): " COUNTRY
read -p "City (Warsaw): " CITY

log "GPS for ${CITY}, ${COUNTRY}..."
RESPONSE=$(curl -s --connect-timeout 10 "https://geocode.maps.co/search?city=${CITY}&country=${COUNTRY}")
[[ -z "$RESPONSE" || "$RESPONSE" == "[]" ]] && error "Location not found."

LAT=$(echo "$RESPONSE" | jq -r '.[0].lat' 2>/dev/null)
LON=$(echo "$RESPONSE" | jq -r '.[0].lon' 2>/dev/null)
[[ -z "$LAT" || -z "$LON" ]] && error "GPS failed."

log "Location: lat=$LAT, lon=$LON"

# Katalogi
mkdir -p ~/.config/redshift ~/.local/{bin,share/{icons,applications}} ~/.config/autostart

# Config redshift
cat > ~/.config/redshift/redshift.conf << EOF
[redshift]
temp-day=5800
temp-night=4800
transition=1
gamma=0.9
location-provider=manual
adjustment-method=randr

[manual]
lat=$LAT
lon=$LON

[randr]
screen=0
EOF

# 📥 Pliki z repo (robust)
log "Downloading files..."
curl -f -L -s -o ~/.local/share/icons/redshift-on.png   "$REPO_URL/redshift-on.png"
curl -f -L -s -o ~/.local/share/icons/redshift-off.png  "$REPO_URL/redshift-off.png"
curl -f -L -s -o ~/.local/bin/redshift-toggle           "$REPO_URL/redshift-toggle.sh"
curl -f -L -s -o ~/.local/share/applications/redshift-toggle.desktop "$REPO_URL/redshift-toggle.desktop"

chmod +x ~/.local/bin/redshift-toggle

# Autostart (safe)
cat > ~/.config/autostart/redshift.desktop << EOF
[Desktop Entry]
Type=Application
Exec=pkill -f redshift >/dev/null 2>&1 || true; redshift -c \$HOME/.config/redshift/redshift.conf
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Redshift
Comment=Auto-start Redshift
EOF

log "✅ Installation COMPLETE!"
echo
echo "🟢 Test: ~/.local/bin/redshift-toggle --menu"
echo "🟢 Panel XFCE: Launcher → Command: ~/.local/bin/redshift-toggle --menu"
echo "🟢 Icon: ~/.local/share/icons/redshift-on.png"
echo "🟢 Reload: source ~/.bashrc"
echo "📦 Ready from GitHub!"

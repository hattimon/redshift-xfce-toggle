#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Adres repozytorium GitHub
REPO_URL="https://raw.githubusercontent.com/hattimon/redshift-xfce-toggle/main"

# Funkcja do wyświetlania komunikatów
log() { echo -e "${GREEN}[*] $1${NC}"; }
error() { echo -e "${RED}[✗] $1${NC}"; exit 1; }

# Dodaj ~/.local/bin do PATH
export PATH="$HOME/.local/bin:$PATH"

# 🔍 Sprawdzanie połączenia internetowego
log "Checking internet connection..."
if ! ping -c 1 archive.ubuntu.com &>/dev/null; then
  error "No internet connection. Check your connection and try again."
fi

# 🔍 Test repozytorium
log "Testing repository access..."
if ! curl -s -f -o /dev/null "$REPO_URL/redshift-toggle.sh"; then
  error "Repository or files not accessible (404?). Check GitHub /tree/main."
fi

# 🔍 Sprawdzanie instalacji redshift i zależności
log "Checking redshift installation..."
if ! command -v redshift >/dev/null 2>&1; then
  log "Redshift not installed. Installing..."
  sudo apt update || log "Warning: Repository issues, continuing..."
  sudo apt install -y redshift curl jq yad xfce4-settings geoclue-2.0 || error "Failed to install required packages."
else
  log "Redshift already installed."
fi

# 🔍 Pobieranie lokalizacji
echo
echo "🌍 Enter location (use Latin names or without diacritics)"
read -p "Country (e.g. Poland): " COUNTRY
read -p "City (e.g. Warsaw): " CITY

log "Searching GPS for ${CITY}, ${COUNTRY}..."
RESPONSE=$(curl -s --connect-timeout 10 "https://geocode.maps.co/search?city=${CITY}&country=${COUNTRY}")

if [[ -z "$RESPONSE" || "$RESPONSE" == "[]" ]]; then
  error "Location not found. Check spelling or internet."
fi

LAT=$(echo "$RESPONSE" | jq -r '.[0].lat' 2>/dev/null)
LON=$(echo "$RESPONSE" | jq -r '.[0].lon' 2>/dev/null)

if [[ -z "$LAT" || -z "$LON" ]]; then
  error "Failed to get GPS coordinates."
fi
log "Found location: lat=$LAT, lon=$LON"

# 🔧 Tworzenie katalogów
mkdir -p ~/.config/redshift ~/.local/bin ~/.local/share/icons ~/.config/autostart ~/.local/share/applications

# 🔧 Konfiguracja Redshift (quoted heredoc)
cat > ~/.config/redshift/redshift.conf << EOF
[redshift]
temp-day=5800
temp-night=4800
transition=1
gamma=0.9
location-provider=manual
adjustment-method=randr

[manual]
lat=${LAT}
lon=${LON}

[randr]
screen=0
EOF

# 📥 Pobieranie ikon
log "Downloading icons..."
for icon in redshift-on.png redshift-off.png; do
  curl -f -L -s -o ~/.local/share/icons/"$icon" "$REPO_URL/$icon" || error "Failed to download icon: $icon"
done

# 📥 Pobieranie skryptu
log "Downloading toggle script..."
curl -f -L -s -o ~/.local/bin/redshift-toggle "$REPO_URL/redshift-toggle.sh" || error "Failed to download redshift-toggle.sh"
chmod +x ~/.local/bin/redshift-toggle

# 📥 Pobieranie .desktop
log "Downloading desktop file..."
curl -f -L -s -o ~/.local/share/applications/redshift-toggle.desktop "$REPO_URL/redshift-toggle.desktop" || error "Failed to download .desktop file"

# 🔧 Autostart Redshift (z pkill dla bezpieczeństwa)
cat > ~/.config/autostart/redshift.desktop << EOF
[Desktop Entry]
Type=Application
Exec=pkill -f redshift || true; redshift -c $HOME/.config/redshift/redshift.conf
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Redshift
Comment=Auto-start Redshift
EOF

# 🔧 Dodaj PATH permanentnie
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc 2>/dev/null || true

log "Installation completed successfully!"
echo
echo "👉 To add XFCE panel launcher:"
echo "1. Right-click XFCE panel → Panel → Add New Items."
echo "2. Select 'Launcher' → Add."
echo "3. Right-click new launcher → Properties."
echo "4. Add new item (+):"
echo "   - Name: Redshift Toggle"
echo "   - Command: $HOME/.local/bin/redshift-toggle --menu"
echo "   - Icon: ~/.local/share/icons/redshift-on.png"
echo "   - Comment: Toggle Redshift or change temp"
echo "5. OK → Close."
echo "🟡 Click icon for menu: On/Off, 4500K, 5500K, 6500K."
echo
echo "Reload: source ~/.bashrc"
echo "📦 Installed from GitHub repo."

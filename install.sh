#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# GitHub repository URL
REPO_URL="https://raw.githubusercontent.com/hattimon/redshift-xfce-toggle/main"

# Message functions
log() { echo -e "${GREEN}[*] $1${NC}"; }
error() { echo -e "${RED}[✗] $1${NC}"; exit 1; }

# 🔍 Checking internet connection
log "Checking internet connection..."
if ! ping -c 1 archive.ubuntu.com &>/dev/null; then
  error "No internet connection. Check your connection and try again."
fi

# 🔍 Checking redshift installation
log "Checking redshift installation..."
if ! command -v redshift >/dev/null 2>&1; then
  log "Redshift not installed. Installing..."
  sudo apt update || log "Warning: Repository issues, continuing installation."
  sudo apt install -y redshift curl yad xfce4-settings || error "Failed to install required packages."
else
  log "Redshift already installed."
fi

# 🔧 Creating directories
mkdir -p ~/.config/redshift ~/.local/bin ~/.local/share/icons ~/.config/autostart ~/.local/share/applications

# 🔧 Redshift configuration (uses system local time CET/CEST - no GPS needed)
cat > ~/.config/redshift/redshift.conf <<EOF
[redshift]
temp-day=5800
temp-night=4800
transition=1
gamma=0.9
location-provider=manual
adjustment-method=randr

[randr]
screen=0
EOF

# 📥 Downloading icons from repository
log "Downloading icons from repository..."
curl -s -o ~/.local/share/icons/redshift-on.png "$REPO_URL/redshift-on.png" || error "Failed to download redshift-on.png icon"
curl -s -o ~/.local/share/icons/redshift-off.png "$REPO_URL/redshift-off.png" || error "Failed to download redshift-off.png icon"

# 📥 Downloading redshift-toggle script
log "Downloading redshift-toggle script..."
curl -s -o ~/.local/bin/redshift-toggle "$REPO_URL/redshift-toggle.sh" || error "Failed to download redshift-toggle.sh script"
chmod +x ~/.local/bin/redshift-toggle

# 📥 Downloading .desktop file
log "Downloading redshift-toggle.desktop file..."
curl -s -o ~/.local/share/applications/redshift-toggle.desktop "$REPO_URL/redshift-toggle.desktop" || error "Failed to download redshift-toggle.desktop file"

# Add PATH permanently
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# 🔧 Redshift autostart
cat > ~/.config/autostart/redshift.desktop <<EOF
[Desktop Entry]
Type=Application
Exec=redshift -c $HOME/.config/redshift/redshift.conf
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Redshift
Comment=Auto-start Redshift (uses system local time)
EOF

log "Installation completed."
echo
echo "👉 To add launcher to XFCE panel, follow these steps:"
echo "1. Right-click XFCE panel (top or bottom bar)."
echo "2. Select 'Panel' → 'Add New Items'."
echo "3. Select 'Launcher' and click 'Add'."
echo "4. Right-click new launcher in panel → 'Properties'."
echo "5. Click 'Add new empty item' (or '+' icon)."
echo "6. Fill fields:"
echo "   - Name: Redshift Toggle"
echo "   - Command: /bin/bash -c \"$HOME/.local/bin/redshift-toggle --menu\""
echo "   - Icon: Select ~/.local/share/icons/redshift-on.png (or enter full path: $HOME/.local/share/icons/redshift-on.png)"
echo "   - Comment (optional): Enable/Disable Redshift or change settings"
echo "7. Click 'OK' to add item and close properties window."
echo "🟡 Clicking panel icon shows menu: On, Off, Temperature 4500K, 5500K, 6500K."
echo
echo "📦 Project installed from GitHub repository. Reload: source ~/.bashrc"

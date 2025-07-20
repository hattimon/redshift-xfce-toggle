#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Adres repozytorium GitHub (zmień na swoje repozytorium)
REPO_URL="https://raw.githubusercontent.com/TWOJ_USERNAME/redshift-xfce-toggle/main"

# Funkcja do wyświetlania komunikatów
log() { echo -e "${GREEN}[*] $1${NC}"; }
error() { echo -e "${RED}[✗] $1${NC}"; exit 1; }

# 🔍 Sprawdzanie instalacji redshift i zależności
log "Sprawdzanie instalacji redshift..."
if ! command -v redshift >/dev/null 2>& stosunki1; then
  log "Redshift nie jest zainstalowany. Instaluję..."
  if ! ping -c 1 archive.ubuntu.com &>/dev/null; then
    log "Brak połączenia z repozytorium – dodaję mirror"
    sudo sed -i 's|http://.*.ubuntu.com|http://archive.ubuntu.com|g' /etc/apt/sources.list
  fi
  sudo apt update
  sudo apt install -y redshift curl jq yad
else
  log "Redshift już zainstalowany."
fi

# 🔍 Pobieranie lokalizacji
echo
echo "🌍 Podaj dane lokalizacji (użyj nazw łacińskich lub bez znaków diakrytycznych)"
read -p "Kraj (np. Poland): " COUNTRY
read -p "Miasto (np. Warsaw): " CITY

log "Szukanie lokalizacji GPS dla ${CITY}, ${COUNTRY}..."
RESPONSE=$(curl -s --connect-timeout 5 "https://geocode.maps.co/search?city=${CITY}&country=${COUNTRY}")

if [[ -z "$RESPONSE" || "$RESPONSE" == "[]" ]]; then
  error "Nie znaleziono lokalizacji. Sprawdź poprawność lub połączenie internetowe."
fi

LAT=$(echo "$RESPONSE" | jq -r '.[0].lat' 2>/dev/null)
LON=$(echo "$RESPONSE" | jq -r '.[0].lon' 2>/dev/null)

if [[ -z "$LAT" || -z "$LON" ]]; then
  error "Nie udało się pobrać współrzędnych GPS."
fi
log "Znaleziono lokalizację: lat=$LAT, lon=$LON"

# 🔧 Tworzenie katalogów
mkdir -p ~/.config/redshift ~/.local/bin ~/.local/share/icons ~/.config/autostart ~/.local/share/applications

# 🔧 Konfiguracja Redshift
cat > ~/.config/redshift/redshift.conf <<EOF
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

# 📥 Pobierzanie ikon z repozytorium
log "Pobieranie ikon z repozytorium..."
curl -s -o ~/.local/share/icons/redshift-on.png "$REPO_URL/redshift-on.png" || error "Nie udało się pobrać ikony redshift-on.png"
curl -s -o ~/.local/share/icons/redshift-off.png "$REPO_URL/redshift-off.png" || error "Nie udało się pobrać ikony redshift-off.png"

# 📥 Pobieranie skryptu redshift-toggle
log "Pobieranie skryptu redshift-toggle..."
curl -s -o ~/.local/bin/redshift-toggle "$REPO_URL/redshift-toggle.sh" || error "Nie udało się pobrać skryptu redshift-toggle.sh"
chmod +x ~/.local/bin/redshift-toggle

# 📥 Pobieranie pliku .desktop
log "Pobieranie pliku redshift-toggle.desktop..."
curl -s -o ~/.local/share/applications/redshift-toggle.desktop "$REPO_URL/redshift-toggle.desktop" || error "Nie udało się pobrać pliku redshift-toggle.desktop"

# 🔧 Autostart Redshift
cat > ~/.config/autostart/redshift.desktop <<EOF
[Desktop Entry]
Type=Application
Exec=redshift -c $HOME/.config/redshift/redshift.conf
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Redshift
Comment=Auto-start Redshift
EOF

log "Instalacja zakończona."
echo
echo "👉 Otwórz Panel XFCE → Dodaj element → Aktywator"
echo "➡️ Edytuj → Dodaj nowy program"
echo "➡️ Wybierz: ~/.local/share/applications/redshift-toggle.desktop"
echo "🟡 Kliknięcie ikony pokaże menu z opcjami: Włącz, Wyłącz, zmiana temperatury barwowej."
echo
echo "📦 Projekt zainstalowany z repozytorium GitHub."
```
#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Adres repozytorium GitHub
REPO_URL="https://github.com/hattimon/redshift-xfce-toggle.git"

# Funkcja do wyświetlania komunikatów
log() { echo -e "${GREEN}[*] $1${NC}"; }
error() { echo -e "${RED}[✗] $1${NC}"; exit 1; }

# 🔍 Sprawdzanie połączenia internetowego
log "Sprawdzanie połączenia internetowego..."
if ! ping -c 1 archive.ubuntu.com &>/dev/null; then
  error "Brak połączenia internetowego. Sprawdź połączenie i spróbuj ponownie."
fi

# 🔍 Sprawdzanie instalacji redshift i zależności
log "Sprawdzanie instalacji redshift..."
if ! command -v redshift >/dev/null 2>&1; then
  log "Redshift nie jest zainstalowany. Instaluję..."
  sudo apt update || log "Ostrzeżenie: Wystąpiły problemy z repozytoriami, ale kontynuuję instalację."
  sudo apt install -y redshift curl jq yad xfce4-settings || error "Nie udało się zainstalować wymaganych pakietów."
else
  log "Redshift już zainstalowany."
fi

# 🔍 Pobieranie lokalizacji
echo
echo "🌍 Podaj dane lokalizacji (użyj nazw łacińskich lub bez znaków diakrytycznych)"
read -p "Kraj Country (np. Poland): " COUNTRY
read -p "Miasto City (np. Warsaw): " CITY

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

# 📥 Pobieranie ikon z repozytorium
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

log "Instalacja zakończona. Installation completed."
echo
echo "👉 Aby dodać aktywator do panelu XFCE, wykonaj następujące kroki:"
echo "1. Kliknij prawym przyciskiem myszy na panelu XFCE (pasek na górze lub dole ekranu)."
echo "2. Wybierz „Panel” → „Dodaj nowy element”."
echo "3. Wybierz „Aktywator” (Launcher) i kliknij „Dodaj”."
echo "4. Kliknij prawym przyciskiem myszy na nowym aktywatorze w panelu → „Właściwości”."
echo "5. Kliknij „Dodaj nowy pusty element” (lub ikonę „+”)."
echo "6. Wypełnij pola:"
echo "   - Nazwa: Redshift Toggle"
echo "   - Polecenie: /bin/bash -c \"$HOME/.local/bin/redshift-toggle --menu\""
echo "   - Ikona: Wybierz ~/.local/share/icons/redshift-on.png (lub wpisz pełną ścieżkę: $HOME/.local/share/icons/redshift-on.png)"
echo "   - Komentarz (opcjonalnie): Włącz/Wyłącz Redshift lub zmień ustawienia"
echo "7. Kliknij „OK”, aby dodać element, i zamknij okno właściwości."
echo "🟡 Kliknięcie ikony w panelu wyświetli menu z opcjami: Włącz, Wyłącz, Temperatura 4500K, 5500K, 6500K."
echo
echo "📦 Projekt zainstalowany z repozytorium GitHub."

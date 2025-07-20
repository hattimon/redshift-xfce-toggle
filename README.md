Redshift XFCE Toggle
Skrypt do instalacji i konfiguracji przełącznika Redshift w panelu XFCE z menu kontekstowym do włączania/wyłączania i zmiany temperatury barwowej.
Wymagania

Linux MX z XFCE
Pakiety: redshift, curl, jq, yad
Połączenie internetowe do pobrania plików z repozytorium

Instalacja

Pobierz i uruchom skrypt instalacyjny:curl -s -o install.sh https://raw.githubusercontent.com/hattimon/redshift-xfce-toggle/main/install.sh
chmod +x install.sh
./install.sh


Podaj kraj i miasto, gdy zostaniesz poproszony.
Dodaj aktywator do panelu XFCE:
Otwórz Panel XFCE → Dodaj element → Aktywator.
Wybierz ~/.local/share/applications/redshift-toggle.desktop.


Kliknij ikonę w panelu, aby zobaczyć menu z opcjami.

Funkcje

Włączanie/wyłączanie Redshift.
Zmiana temperatury barwowej (4500K, 5500K, 6500K).
Automatyczne uruchamianie Redshift przy starcie systemu.

Licencja
MIT

Redshift XFCE Toggle
Skrypt do instalacji i konfiguracji przełącznika Redshift w panelu XFCE z menu kontekstowym do włączania/wyłączania i zmiany temperatury barwowej.
Wymagania

Linux MX z XFCE
Pakiety: redshift, curl, jq, yad, xfce4-settings
Połączenie internetowe do pobrania plików z repozytorium

Instalacja

Pobierz i uruchom skrypt instalacyjny:curl -s -o install.sh https://raw.githubusercontent.com/hattimon/redshift-xfce-toggle/main/install.sh
chmod +x install.sh
./install.sh


Podaj kraj i miasto (np. Poland, Warsaw), gdy zostaniesz poproszony.
Dodaj aktywator do panelu XFCE:
Kliknij prawym przyciskiem myszy na panelu XFCE (pasek na górze lub dole ekranu).
Wybierz „Panel” → „Dodaj nowy element”.
Wybierz „Aktywator” (Launcher) i kliknij „Dodaj”.
Kliknij prawym przyciskiem myszy na nowym aktywatorze w panelu → „Właściwości”.
Kliknij „Dodaj nowy pusty element” (lub ikonę „+”).
Wypełnij pola:
Nazwa: Redshift Toggle
Polecenie: /bin/bash -c "$HOME/.local/bin/redshift-toggle --menu"
Ikona: Wybierz ~/.local/share/icons/redshift-on.png (lub wpisz pełną ścieżkę: $HOME/.local/share/icons/redshift-on.png)
Komentarz (opcjonalnie): Włącz/Wyłącz Redshift lub zmień ustawienia


Kliknij „OK” i zamknij okno właściwości.


Kliknij ikonę w panelu, aby zobaczyć menu z opcjami: Włącz, Wyłącz, Temperatura 4500K, 5500K, 6500K.

Funkcje

Włączanie/wyłączanie Redshift z dynamiczną zmianą ikony w panelu.
Zmiana temperatury barwowej (4500K, 5500K, 6500K).
Automatyczne uruchamianie Redshift przy starcie systemu.

Rozwiązywanie problemów

Jeśli menu kontekstowe nie działa, upewnij się, że yad jest zainstalowany:sudo apt install yad


Jeśli ikona nie zmienia się, sprawdź dostępność xfce4-settings:sudo apt install xfce4-settings


Sprawdź logi skryptu:bash -x ~/.local/bin/redshift-toggle --menu



Licencja
MIT

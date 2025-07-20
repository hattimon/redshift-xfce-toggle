#!/bin/bash

echo "🗑️  Usuwanie Redshift Toggle..."

# Pliki do usunięcia
FILES=(
  "$HOME/.local/bin/redshift-toggle"
  "$HOME/.config/redshift/redshift.conf"
  "$HOME/.local/share/applications/redshift-toggle.desktop"
  "$HOME/.config/autostart/redshift.desktop"
)

for FILE in "${FILES[@]}"; do
  if [ -e "$FILE" ]; then
    rm -f "$FILE" && echo "✔️  Usunięto: $FILE"
  else
    echo "⚠️  Nie znaleziono: $FILE"
  fi
done

echo "✅ Redshift Toggle został odinstalowany."

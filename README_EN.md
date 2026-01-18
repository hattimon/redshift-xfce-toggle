# Redshift XFCE Toggle

An installation script that allows you to quickly add a **Redshift** toggle to the **XFCE** panel, with a convenient menu for:
- enabling/disabling Redshift,
- changing color temperature (4500K, 5500K, 6500K).

---

## 🧰 Requirements

- System: **Linux MX** (deb) with **XFCE** desktop environment
- Internet connection

> ℹ️ Required packages (`redshift`, `curl`, `jq`, `yad`, `xfce4-settings`) will be **automatically installed** by the script.

---

## 🚀 Installation

1. Download and run the installer:

   curl -s -o install.sh https://raw.githubusercontent.com/hattimon/redshift-xfce-toggle/main/install.sh  
   chmod +x install.sh  
   ./install.sh

2. Enter your country and city (e.g. `Poland`, `Warsaw`) when prompted.

3. After installation, add the launcher to the XFCE panel:

   - **Right-click** on the XFCE panel.
   - Select: `Panel` → `Add New Items`.
   - Choose: `Launcher` and click `Add`.
   - Right-click the new launcher → `Properties`.
   - Click `Add new empty item` (or the `+` icon).

4. Fill in the details:

   - **Name**: `Redshift Toggle`
   - **Comment (optional)**: `Enable/Disable Redshift or change settings`
   - **Command**:

     /bin/bash -c "$HOME/.local/bin/redshift-toggle --menu"

   - **Click the Icon field**, type `Redshift`, and select the icon

   (Image: Redshift.png)

5. Click `OK` to save and close the properties window.

7. Restart the system (without this step it may not work correctly).

8. Click the icon in the XFCE panel to open the menu with options:
   - `Enable`
   - `Disable`
   - `Temperature 4500K`
   - `Temperature 5500K`
   - `Temperature 6500K`

(Image: menu.png)

> ⚠️ **After changing the color temperature, you must select “Enable” again** to apply the new settings.

---

## ✨ Features

- Convenient Redshift on/off toggle from the panel
- Color temperature switching: `4500K`, `5500K`, `6500K`
- Automatic Redshift startup on system login

---

## 🛠️ Troubleshooting

- **Context menu does not appear?**  
  Make sure `yad` is installed:

  sudo apt install yad

- **Check script execution and possible errors**:

  bash -x ~/.local/bin/redshift-toggle --menu

---

## 📦 Installed Files

- `~/.config/redshift/redshift.conf` – Redshift configuration
- `~/.local/bin/redshift-toggle` – context menu script
- `~/.config/autostart/redshift.desktop` – Redshift autostart on login
- `~/.local/share/applications/redshift-toggle.desktop` – application menu entry

---

## 📄 License

This project is licensed under the **MIT** License. See the [LICENSE](./LICENSE) file.

---

## 🧹 Uninstallation

To completely remove Redshift Toggle and all related files:

1. Download the uninstall script:

   curl -s -o uninstall.sh https://raw.githubusercontent.com/hattimon/redshift-xfce-toggle/main/uninstall.sh  
   chmod +x uninstall.sh  
   ./uninstall.sh

2. Remove the launcher from the XFCE panel by right-clicking it → `Remove`.

> The script removes only files installed by Redshift Toggle — your personal data and other Redshift settings are not affected.

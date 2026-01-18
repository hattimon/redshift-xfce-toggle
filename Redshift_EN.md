# Redshift XFCE Toggle

Installation script that lets you quickly add a **Redshift** toggle to
the **XFCE** panel with a convenient menu to: - enable/disable
Redshift, - change the color temperature (4500K, 5500K, 6500K).

------------------------------------------------------------------------

## 🧰 Requirements

-   System: **Linux MX** (deb) with **XFCE** desktop environment
-   Internet connection

> ℹ️ Required packages (`redshift`, `curl`, `jq`, `yad`,
> `xfce4-settings`) will be **installed automatically** by the script.

------------------------------------------------------------------------

## 🚀 Installation

1.  Download and run the installer:

``` bash
curl -s -o install.sh https://raw.githubusercontent.com/hattimon/redshift-xfce-toggle/main/install.sh
chmod +x install.sh
./install.sh
```

2.  Enter your country and city (e.g. `Poland`, `Warsaw`) when prompted.

3.  After installation, add the launcher to the XFCE panel:

-   Right‑click on the XFCE panel.
-   Choose: `Panel` → `Add New Items`.
-   Select: `Launcher` and click `Add`.
-   Right‑click the new launcher → `Properties`.
-   Click `Add new empty item` (or the `+` icon).

4.  Fill in the details:

-   **Name**: `Redshift Toggle`
-   **Comment (optional)**: `Enable/Disable Redshift or change settings`
-   **Command**:

``` bash
/bin/bash -c "$HOME/.local/bin/redshift-toggle --menu"
```

-   **Click Icon** → type `Redshift` and choose the icon

![Redshift](Redshift.png)

5.  Click `OK` to save and close the properties window.

6.  Restart the system (without this it may not work correctly).

7.  Click the icon in the XFCE panel to open the menu with options:

-   `Enable`
-   `Disable`
-   `Temperature 4500K`
-   `Temperature 5500K`
-   `Temperature 6500K`

![MENU](menu.png)

> ⚠️ **After changing the color temperature you must select "Enable"
> again** to apply the new settings.

------------------------------------------------------------------------

## ✨ Features

-   Convenient enable/disable of Redshift from the panel
-   Color temperature switching: `4500K`, `5500K`, `6500K`
-   Automatic start of Redshift at system login

------------------------------------------------------------------------

## 🛠️ Troubleshooting

-   **Context menu not showing?**\
    Make sure `yad` is installed:

``` bash
sudo apt install yad
```

-   **Check script execution and possible errors:**

``` bash
bash -x ~/.local/bin/redshift-toggle --menu
```

------------------------------------------------------------------------

## 📦 Installed files

-   `~/.config/redshift/redshift.conf` -- Redshift configuration
-   `~/.local/bin/redshift-toggle` -- context menu script
-   `~/.config/autostart/redshift.desktop` -- Redshift autostart on
    login
-   `~/.local/share/applications/redshift-toggle.desktop` -- application
    menu entry

------------------------------------------------------------------------

## 📄 License

This project is licensed under the **MIT** License. See the
[LICENSE](./LICENSE) file.

------------------------------------------------------------------------

## 🧹 Uninstall

To completely remove Redshift Toggle and all related files:

1.  Download the uninstall script:

``` bash
curl -s -o uninstall.sh https://raw.githubusercontent.com/hattimon/redshift-xfce-toggle/main/uninstall.sh
chmod +x uninstall.sh
./uninstall.sh
```

2.  Remove the launcher from the XFCE panel by right‑clicking it →
    `Remove`.

> The script only removes files installed by Redshift Toggle --- your
> personal data and other Redshift settings are not touched.

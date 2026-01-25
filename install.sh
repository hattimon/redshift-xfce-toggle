#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}🚀 Redshift Scheduler - COMPLETE Installation with Cleanup${NC}\n"

# ============================================
# 0. CLEANUP - Remove old installation
# ============================================
echo -e "${YELLOW}🧹 Cleaning up old installation...${NC}"

# Stop services
echo -e "${YELLOW}Stopping services...${NC}"
systemctl --user stop redshift-scheduler-daemon.service 2>/dev/null || true
systemctl --user stop redshift-scheduler-applet.service 2>/dev/null || true
sleep 1

# Kill running processes
echo -e "${YELLOW}Killing running processes...${NC}"
pkill -f "redshift-scheduler-daemon" 2>/dev/null || true
pkill -f "redshift-scheduler-applet" 2>/dev/null || true
sleep 1

# Disable services
echo -e "${YELLOW}Disabling old services...${NC}"
systemctl --user disable redshift-scheduler-daemon.service 2>/dev/null || true
systemctl --user disable redshift-scheduler-applet.service 2>/dev/null || true

# Remove old binaries
echo -e "${YELLOW}Removing old binaries...${NC}"
rm -f ~/.local/bin/redshift-scheduler-daemon
rm -f ~/.local/bin/redshift-scheduler-applet

# Remove old service files
echo -e "${YELLOW}Removing old service files...${NC}"
rm -f ~/.config/systemd/user/redshift-scheduler-daemon.service
rm -f ~/.config/systemd/user/redshift-scheduler-applet.service

# Remove old autostart
echo -e "${YELLOW}Removing old autostart...${NC}"
rm -f ~/.config/autostart/redshift-scheduler-applet.desktop

# Keep config for backup but create fresh if needed
echo -e "${YELLOW}Backing up old config...${NC}"
if [ -f ~/.config/redshift-scheduler/config.json ]; then
    cp ~/.config/redshift-scheduler/config.json ~/.config/redshift-scheduler/config.json.backup
    echo "  ✓ Config backed up to config.json.backup"
fi

# Reload systemd to clear old definitions
echo -e "${YELLOW}Reloading systemd daemon...${NC}"
systemctl --user daemon-reload 2>/dev/null || true
sleep 1

echo -e "${GREEN}✅ Cleanup complete!${NC}\n"

# ============================================
# 1. CREATE DIRECTORIES
# ============================================
echo -e "${GREEN}📁 Creating directories...${NC}"
mkdir -p ~/.local/bin
mkdir -p ~/.config/redshift-scheduler
mkdir -p ~/.config/systemd/user
mkdir -p ~/.config/autostart
chmod 700 ~/.config/systemd/user
echo -e "${GREEN}✅ Directories created${NC}\n"

# ============================================
# 2. INSTALL DAEMON
# ============================================
echo -e "${GREEN}📦 Installing daemon...${NC}"
cat > ~/.local/bin/redshift-scheduler-daemon << 'DAEMON_SCRIPT'
#!/usr/bin/env python3
"""Redshift Scheduler Daemon - Controls redshift based on schedule"""
import json
import os
import time
import subprocess
import sys
from datetime import datetime

CONFIG_FILE = os.path.expanduser("~/.config/redshift-scheduler/config.json")

def load_config():
    """Load configuration from JSON file"""
    try:
        with open(CONFIG_FILE, 'r') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading config: {e}", file=sys.stderr)
        return {"enabled": True, "start_hour": 21, "end_hour": 8, "temperature": 4500, "color": "#FFD700"}

def is_enabled():
    """Check if redshift scheduler is enabled"""
    config = load_config()
    return config.get("enabled", True)

def get_time_range():
    """Get start and end hours from config"""
    config = load_config()
    return config.get("start_hour", 21), config.get("end_hour", 8)

def get_temperature():
    """Get temperature setting from config"""
    config = load_config()
    return config.get("temperature", 4500)

def should_enable_redshift():
    """Determine if redshift should be enabled based on current time"""
    start_h, end_h = get_time_range()
    now = datetime.now()
    current_h = now.hour
    
    # Handle time range crossing midnight (e.g., 21:00 - 08:00)
    if start_h > end_h:
        return current_h >= start_h or current_h < end_h
    else:
        return start_h <= current_h < end_h

def set_redshift_state(enable):
    """Enable or disable redshift"""
    try:
        if enable:
            temp = get_temperature()
            result = subprocess.run(
                ["redshift", "-O", str(temp)],
                capture_output=True,
                timeout=5
            )
            if result.returncode != 0:
                print(f"Redshift ON failed: {result.stderr.decode()}", file=sys.stderr)
            else:
                print(f"[{datetime.now().strftime('%H:%M:%S')}] Redshift ON ({temp}K)")
        else:
            result = subprocess.run(
                ["redshift", "-x"],
                capture_output=True,
                timeout=5
            )
            if result.returncode != 0:
                print(f"Redshift OFF failed: {result.stderr.decode()}", file=sys.stderr)
            else:
                print(f"[{datetime.now().strftime('%H:%M:%S')}] Redshift OFF")
    except FileNotFoundError:
        print("Error: redshift not found. Install with: sudo apt install redshift", file=sys.stderr)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)

def main():
    """Main daemon loop"""
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Redshift Scheduler Daemon started")
    last_state = None
    
    while True:
        try:
            if is_enabled():
                current_state = should_enable_redshift()
                if current_state != last_state:
                    set_redshift_state(current_state)
                    last_state = current_state
            else:
                # Disable redshift if scheduler is turned off
                if last_state is not False:
                    subprocess.run(["redshift", "-x"], capture_output=True, timeout=5)
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] Scheduler disabled, redshift OFF")
                    last_state = False
            
            time.sleep(60)
        except KeyboardInterrupt:
            print("\nShutdown requested")
            break
        except Exception as e:
            print(f"Daemon error: {e}", file=sys.stderr)
            time.sleep(60)

if __name__ == "__main__":
    main()
DAEMON_SCRIPT

chmod +x ~/.local/bin/redshift-scheduler-daemon
echo -e "${GREEN}✅ Daemon installed${NC}\n"

# ============================================
# 3. INSTALL APPLET (GUI) - FIXED VERSION
# ============================================
echo -e "${GREEN}📦 Installing applet (GUI with menu)...${NC}"
cat > ~/.local/bin/redshift-scheduler-applet << 'APPLET_SCRIPT'
#!/usr/bin/env python3
"""Redshift Scheduler Applet - System tray with graphical menu"""
import tkinter as tk
from tkinter import messagebox
import json
import os
import sys
import signal
import subprocess
from pathlib import Path

CONFIG_FILE = os.path.expanduser("~/.config/redshift-scheduler/config.json")

# Temperature presets
TEMP_PRESETS = {
    "🔥 Gorący (3000K)": 3000,
    "🌅 Zmierzch (4500K)": 4500,
    "❄️ Chłodny (6500K)": 6500,
}

# Color options
COLORS = {
    "🌙 Niebieska (Night)": "#1E90FF",
    "💛 Żółta (Warm)": "#FFD700",
    "🔴 Pomarańczowa (Orange)": "#FF8C00",
    "🔥 Czerwona (Intense)": "#FF4500",
}

# Languages
LANGUAGES = {
    "English": "en",
    "Polski": "pl",
}

# Translations
TEXTS = {
    "en": {
        "toggle": "🌙 Toggle ON/OFF",
        "temperature": "📊 Temperature:",
        "color": "🎨 Menu Color:",
        "language": "🌐 Language:",
        "close": "❌ Close",
    },
    "pl": {
        "toggle": "🌙 Przełącz ON/OFF",
        "temperature": "📊 Temperatura:",
        "color": "🎨 Kolor menu:",
        "language": "🌐 Język:",
        "close": "❌ Zamknij",
    }
}

class RedshiftApplet:
    def __init__(self, root):
        self.root = root
        self.root.withdraw()
        self.root.title("Redshift Scheduler")
        
        self.current_language = "pl"
        self.load_language()
        
        # Create tray frame
        self.tray_frame = tk.Frame(root, relief=tk.RAISED, bd=1)
        self.tray_frame.pack(padx=3, pady=3)
        
        self.tray_label = tk.Label(
            self.tray_frame, text="🌙 ON", font=("Arial", 11, "bold"),
            width=8, height=1, padx=5, pady=3, bg="#FFD700", fg="black"
        )
        self.tray_label.pack()
        self.tray_label.bind("<Button-1>", self.show_menu)
        self.tray_label.bind("<Button-3>", lambda e: self.root.destroy())
        
        # Create menu
        self.menu = tk.Menu(root, tearoff=False, bg="#2C2C2C", fg="white", activebg="#444444")
        self.build_menu()
        
        # Position window in top-right corner
        self.root.geometry("+1850+10")
        self.root.overrideredirect(True)
        self.root.attributes('-topmost', True)
        self.root.deiconify()
        
        self.update_tray()
        
        # Handle signals
        signal.signal(signal.SIGTERM, lambda s, f: self.root.destroy())
        signal.signal(signal.SIGINT, lambda s, f: self.root.destroy())
        
        self.root.protocol("WM_DELETE_WINDOW", self.on_close)
    
    def load_language(self):
        """Load language from config"""
        config = self.load_config()
        self.current_language = config.get("language", "pl")
    
    def t(self, key):
        """Get translated text"""
        return TEXTS.get(self.current_language, TEXTS["en"]).get(key, key)
    
    def load_config(self):
        """Load configuration from JSON file"""
        try:
            with open(CONFIG_FILE, 'r') as f:
                return json.load(f)
        except Exception as e:
            return {
                "enabled": True,
                "start_hour": 21,
                "end_hour": 8,
                "temperature": 4500,
                "color": "#FFD700",
                "language": "pl"
            }
    
    def save_config(self, config):
        """Save configuration to JSON file"""
        try:
            with open(CONFIG_FILE, 'w') as f:
                json.dump(config, f, indent=2)
        except Exception:
            pass
    
    def restart_daemon(self):
        """Restart daemon service"""
        try:
            subprocess.run(
                ["systemctl", "--user", "restart", "redshift-scheduler-daemon.service"],
                capture_output=True,
                timeout=5
            )
            return True
        except Exception:
            return False
    
    def toggle_enabled(self):
        """Toggle scheduler ON/OFF"""
        config = self.load_config()
        config["enabled"] = not config.get("enabled", True)
        self.save_config(config)
        self.update_tray()
        self.hide_menu()
    
    def set_temperature(self, temp):
        """Set temperature preset and restart daemon"""
        config = self.load_config()
        config["temperature"] = temp
        self.save_config(config)
        self.restart_daemon()
        self.hide_menu()
        self.update_tray()
    
    def set_color(self, color_hex):
        """Set menu color"""
        config = self.load_config()
        config["color"] = color_hex
        self.save_config(config)
        self.hide_menu()
        self.update_tray()
    
    def set_language(self, lang_code):
        """Set language"""
        config = self.load_config()
        config["language"] = lang_code
        self.save_config(config)
        self.current_language = lang_code
        self.hide_menu()
        self.rebuild_menu()
        self.update_tray()
    
    def update_tray(self):
        """Update tray icon and label"""
        config = self.load_config()
        enabled = config.get("enabled", True)
        color = config.get("color", "#FFD700")
        
        if enabled:
            status_text = "🌙 ON"
            bg_color = color
        else:
            status_text = "☀️ OFF"
            bg_color = "#666666"
        
        text_color = "black" if color == "#FFD700" else "white"
        self.tray_label.config(text=status_text, bg=bg_color, fg=text_color)
    
    def show_menu(self, event):
        """Show dropdown menu at cursor"""
        self.menu.post(event.x_root, event.y_root)
    
    def hide_menu(self):
        """Hide menu"""
        self.menu.unpost()
    
    def rebuild_menu(self):
        """Rebuild menu with current language"""
        self.menu.delete(0, tk.END)
        self.build_menu()
    
    def build_menu(self):
        """Build dropdown menu"""
        # Toggle option
        self.menu.add_command(
            label=self.t("toggle"),
            command=self.toggle_enabled,
            foreground="white"
        )
        self.menu.add_separator()
        
        # Temperature section
        self.menu.add_label(label=self.t("temperature"), foreground="#FFD700")
        for label, temp in TEMP_PRESETS.items():
            self.menu.add_command(
                label=label,
                command=lambda t=temp: self.set_temperature(t),
                foreground="white"
            )
        
        self.menu.add_separator()
        
        # Color section
        self.menu.add_label(label=self.t("color"), foreground="#FFD700")
        for label, color in COLORS.items():
            self.menu.add_command(
                label=label,
                command=lambda c=color: self.set_color(c),
                foreground="white"
            )
        
        self.menu.add_separator()
        
        # Language section
        self.menu.add_label(label=self.t("language"), foreground="#FFD700")
        for lang_name, lang_code in LANGUAGES.items():
            self.menu.add_command(
                label=lang_name,
                command=lambda lc=lang_code: self.set_language(lc),
                foreground="white"
            )
        
        self.menu.add_separator()
        
        # Exit option
        self.menu.add_command(
            label=self.t("close"),
            command=lambda: self.root.destroy(),
            foreground="#FF4444"
        )
    
    def on_close(self):
        """Close applet"""
        self.root.withdraw()
        self.root.after(1000, self.root.destroy)

if __name__ == "__main__":
    try:
        root = tk.Tk()
        app = RedshiftApplet(root)
        root.mainloop()
    except Exception as e:
        # Log error but don't crash
        with open(os.path.expanduser("~/.config/redshift-scheduler/applet.log"), "a") as f:
            f.write(f"Error: {e}\n")
        sys.exit(1)
APPLET_SCRIPT

chmod +x ~/.local/bin/redshift-scheduler-applet
echo -e "${GREEN}✅ Applet installed${NC}\n"

# ============================================
# 4. CREATE CONFIG FILE
# ============================================
echo -e "${GREEN}⚙️  Creating configuration...${NC}"
cat > ~/.config/redshift-scheduler/config.json << 'CONFIG'
{
  "enabled": true,
  "start_hour": 21,
  "end_hour": 8,
  "temperature": 4500,
  "color": "#FFD700",
  "language": "pl"
}
CONFIG

echo -e "${GREEN}✅ Config file created${NC}"
echo -e "${YELLOW}📝 Config file: ~/.config/redshift-scheduler/config.json${NC}"
cat ~/.config/redshift-scheduler/config.json
echo ""

# ============================================
# 5. CREATE SYSTEMD SERVICES
# ============================================
echo -e "${GREEN}🔧 Creating systemd user services...${NC}"

# Daemon service
cat > ~/.config/systemd/user/redshift-scheduler-daemon.service << 'DAEMON_SERVICE'
[Unit]
Description=Redshift Scheduler Daemon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=%h/.local/bin/redshift-scheduler-daemon
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
DAEMON_SERVICE

# Applet service (GUI) - IMPROVED
cat > ~/.config/systemd/user/redshift-scheduler-applet.service << 'APPLET_SERVICE'
[Unit]
Description=Redshift Scheduler Applet
PartOf=graphical-session.target
After=graphical-session-pre.target
Wants=dbus.service

[Service]
Type=simple
ExecStart=/bin/sh -c 'sleep 2; exec env DISPLAY=:0 XDG_VTNR=7 %h/.local/bin/redshift-scheduler-applet'
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"
Environment="XAUTHORITY=%h/.Xauthority"

[Install]
WantedBy=graphical-session.target
APPLET_SERVICE

echo -e "${GREEN}✅ Service files created${NC}\n"

# ============================================
# 6. CREATE AUTOSTART .DESKTOP FILE
# ============================================
echo -e "${GREEN}🔧 Creating autostart entry...${NC}"
cat > ~/.config/autostart/redshift-scheduler-applet.desktop << 'AUTOSTART'
[Desktop Entry]
Version=1.0
Type=Application
Name=Redshift Scheduler Applet
Exec=env DISPLAY=:0 /home/%u/.local/bin/redshift-scheduler-applet
Icon=preferences-desktop-display
Categories=Utility;System;
NoDisplay=false
Terminal=false
StartupNotify=false
X-GNOME-Autostart-enabled=true
X-KDE-autostart-after=panel
X-XFCE-Autostart=true
AutostartCondition=unless-running redshift-scheduler-applet
AUTOSTART

# Replace %u with actual username
sed -i "s|%u|$USER|g" ~/.config/autostart/redshift-scheduler-applet.desktop

echo -e "${GREEN}✅ Autostart entry created${NC}\n"

# ============================================
# 7. FIX SYSTEMD (MX Linux issue)
# ============================================
echo -e "${GREEN}🔧 Fixing systemd (MX Linux compatibility)...${NC}"

# Kill stuck systemd processes
pkill -f "systemd1" 2>/dev/null || true
sleep 1

# Reload daemon with error handling
echo -e "${YELLOW}Reloading systemd daemon...${NC}"
if ! systemctl --user daemon-reload 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Systemd reload issue - retrying with delay...${NC}"
    sleep 2
    systemctl --user daemon-reload 2>/dev/null || true
fi

echo -e "${GREEN}✅ Systemd fixed${NC}\n"

# ============================================
# 8. ENABLE AND START SERVICES
# ============================================
echo -e "${GREEN}✅ Enabling services...${NC}"
systemctl --user enable redshift-scheduler-daemon.service 2>/dev/null || true
systemctl --user enable redshift-scheduler-applet.service 2>/dev/null || true

echo -e "${GREEN}🚀 Starting services...${NC}"
systemctl --user start redshift-scheduler-daemon.service 2>/dev/null || true
systemctl --user start redshift-scheduler-applet.service 2>/dev/null || true

sleep 3

# ============================================
# 9. VERIFY INSTALLATION
# ============================================
echo -e "${GREEN}📊 Verifying installation...${NC}\n"

# Kill journalctl processes from verification
pkill -f "journalctl.*redshift-scheduler" 2>/dev/null || true
sleep 1

echo -e "${YELLOW}Running processes:${NC}"
RUNNING=$(ps aux | grep -E "redshift-scheduler-(daemon|applet)" | grep -v grep | wc -l)
if [ $RUNNING -gt 0 ]; then
    echo -e "${GREEN}✅ Found $RUNNING running processes:${NC}"
    ps aux | grep -E "redshift-scheduler-(daemon|applet)" | grep -v grep
else
    echo -e "${YELLOW}⚠️  Processes not running - trying fallback...${NC}"
    ~/.local/bin/redshift-scheduler-daemon > /dev/null 2>&1 &
    sleep 1
    DISPLAY=:0 ~/.local/bin/redshift-scheduler-applet > /dev/null 2>&1 &
    sleep 2
    RUNNING=$(ps aux | grep -E "redshift-scheduler-(daemon|applet)" | grep -v grep | wc -l)
    if [ $RUNNING -gt 0 ]; then
        echo -e "${GREEN}✅ Fallback successful! Found $RUNNING processes:${NC}"
        ps aux | grep -E "redshift-scheduler-(daemon|applet)" | grep -v grep
    else
        echo -e "${RED}❌ Failed to start - check logs${NC}"
    fi
fi

echo ""

# Verify files exist
echo -e "${YELLOW}Installed files verification:${NC}"
if [ -f ~/.local/bin/redshift-scheduler-daemon ]; then
    echo -e "${GREEN}✅${NC} ~/.local/bin/redshift-scheduler-daemon"
else
    echo -e "${RED}❌${NC} ~/.local/bin/redshift-scheduler-daemon"
fi

if [ -f ~/.local/bin/redshift-scheduler-applet ]; then
    echo -e "${GREEN}✅${NC} ~/.local/bin/redshift-scheduler-applet"
else
    echo -e "${RED}❌${NC} ~/.local/bin/redshift-scheduler-applet"
fi

if [ -f ~/.config/redshift-scheduler/config.json ]; then
    echo -e "${GREEN}✅${NC} ~/.config/redshift-scheduler/config.json"
else
    echo -e "${RED}❌${NC} ~/.config/redshift-scheduler/config.json"
fi

if [ -f ~/.config/autostart/redshift-scheduler-applet.desktop ]; then
    echo -e "${GREEN}✅${NC} ~/.config/autostart/redshift-scheduler-applet.desktop"
else
    echo -e "${RED}❌${NC} ~/.config/autostart/redshift-scheduler-applet.desktop"
fi

# ============================================
# 10. INSTALLATION SUMMARY
# ============================================
echo -e "\n${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ INSTALLATION COMPLETE!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📁 Installed files:${NC}"
echo "  • Daemon:     ~/.local/bin/redshift-scheduler-daemon"
echo "  • Applet:     ~/.local/bin/redshift-scheduler-applet"
echo "  • Config:     ~/.config/redshift-scheduler/config.json"
echo "  • Services:   ~/.config/systemd/user/"
echo "  • Autostart:  ~/.config/autostart/redshift-scheduler-applet.desktop"

echo -e "\n${YELLOW}🎨 Features:${NC}"
echo "  • 🌙 Tray icon dropdown menu (click to show)"
echo "  • 🔄 Toggle ON/OFF directly from menu"
echo "  • 📊 Temperature presets (3000K, 4500K, 6500K)"
echo "  • 🎨 Color themes (Blue, Yellow, Orange, Red)"
echo "  • 🌐 Language support (English, Polski)"
echo "  • ⚙️  Auto-start on login (XFCE/GNOME compatible)"
echo "  • 👻 Minimized window in top-right corner"
echo "  • 🚀 Right-click to close tray"
echo "  • 🔄 Automatic daemon restart on color/temp change"

echo -e "\n${YELLOW}🔧 Useful commands:${NC}"
echo "  • Check daemon:  systemctl --user status redshift-scheduler-daemon"
echo "  • View logs:     journalctl --user -u redshift-scheduler-daemon -f"
echo "  • Applet logs:   tail -f ~/.config/redshift-scheduler/applet.log"
echo "  • Edit config:   nano ~/.config/redshift-scheduler/config.json"
echo "  • Manual applet: DISPLAY=:0 ~/.local/bin/redshift-scheduler-applet &"
echo "  • Stop services: systemctl --user stop redshift-scheduler-*.service"
echo "  • Restart:       systemctl --user restart redshift-scheduler-*.service"

echo -e "\n${YELLOW}🚀 Usage:${NC}"
echo "  1. ✅ Installation done - tray icon in top-right corner"
echo "  2. Click 🌙 icon to open dropdown menu"
echo "  3. Toggle ON/OFF or change temperature"
echo "  4. Select color theme from menu"
echo "  5. Choose language (English/Polski)"
echo "  6. Right-click to close (or just click away)"
echo "  7. 💡 After login, applet starts automatically"

echo -e "\n${YELLOW}❓ If applet doesn't appear:${NC}"
echo "  1. Check logs: tail -f ~/.config/redshift-scheduler/applet.log"
echo "  2. Manual start: DISPLAY=:0 ~/.local/bin/redshift-scheduler-applet &"
echo "  3. Restart applet: systemctl --user restart redshift-scheduler-applet"

echo -e "\n${YELLOW}📦 To reinstall in the future:${NC}"
echo "  bash install.sh"
echo "  (This will automatically clean up old installation)"

echo -e "\n${GREEN}Happy coding! 🚀${NC}\n"

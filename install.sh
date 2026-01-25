#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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
# 3. INSTALL APPLET (GUI) - TRAY ICON WITH MENU
# ============================================
echo -e "${GREEN}📦 Installing applet (GUI with tray)...${NC}"
cat > ~/.local/bin/redshift-scheduler-applet << 'APPLET_SCRIPT'
#!/usr/bin/env python3
"""Redshift Scheduler Applet - System tray with dropdown menu"""
import tkinter as tk
from tkinter import messagebox
import json
import os
import sys
import signal
import subprocess

CONFIG_FILE = os.path.expanduser("~/.config/redshift-scheduler/config.json")

# Temperature presets with colors
TEMP_PRESETS = {
    "🔥 Gorący (3000K)": 3000,
    "🌅 Zmierzch (4500K)": 4500,
    "❄️ Chłodny (6500K)": 6500,
}

# Color options for menu
COLORS = {
    "🌙 Niebieska (Night)": "#1E90FF",
    "💛 Żółta (Warm)": "#FFD700",
    "🔴 Pomarańczowa (Orange)": "#FF8C00",
    "🔥 Czerwona (Intense)": "#FF4500",
}

def load_config():
    """Load configuration from JSON file"""
    try:
        with open(CONFIG_FILE, 'r') as f:
            return json.load(f)
    except Exception as e:
        return {"enabled": True, "start_hour": 21, "end_hour": 8, "temperature": 4500, "color": "#FFD700"}

def save_config(config):
    """Save configuration to JSON file"""
    try:
        with open(CONFIG_FILE, 'w') as f:
            json.dump(config, f, indent=2)
    except Exception as e:
        pass

def toggle_enabled():
    """Toggle scheduler ON/OFF"""
    config = load_config()
    config["enabled"] = not config.get("enabled", True)
    save_config(config)
    update_tray()
    hide_menu()

def set_temperature(temp):
    """Set temperature preset"""
    config = load_config()
    config["temperature"] = temp
    save_config(config)
    hide_menu()
    update_tray()

def set_color(color_hex):
    """Set menu color"""
    config = load_config()
    config["color"] = color_hex
    save_config(config)
    hide_menu()
    update_tray()

def update_tray():
    """Update tray icon and label"""
    config = load_config()
    enabled = config.get("enabled", True)
    color = config.get("color", "#FFD700")
    
    if enabled:
        status_text = "🌙 ON"
        bg_color = color
    else:
        status_text = "☀️ OFF"
        bg_color = "#666666"
    
    tray_label.config(text=status_text, bg=bg_color, fg="black" if color == "#FFD700" else "white")

def show_menu(event):
    """Show dropdown menu at cursor"""
    menu.post(event.x_root, event.y_root)

def hide_menu():
    """Hide menu"""
    menu.unpost()

def on_close():
    """Close applet and hide from taskbar"""
    root.withdraw()
    root.after(1000, root.destroy)

# Create main window (hidden)
root = tk.Tk()
root.withdraw()
root.title("Redshift Scheduler")

# Create tray icon (clickable label)
tray_frame = tk.Frame(root, relief=tk.RAISED, bd=1)
tray_frame.pack(padx=3, pady=3)

tray_label = tk.Label(tray_frame, text="🌙 ON", font=("Arial", 11, "bold"), 
                       width=8, height=1, padx=5, pady=3, bg="#FFD700", fg="black")
tray_label.pack()
tray_label.bind("<Button-1>", show_menu)
tray_label.bind("<Button-3>", lambda e: root.destroy())  # Right-click to close

# Create dropdown menu
menu = tk.Menu(root, tearoff=False, bg="#2C2C2C", fg="white", activebg="#444444")

# Toggle option
menu.add_command(label="🌙 Toggle ON/OFF", command=toggle_enabled, foreground="white")
menu.add_separator()

# Temperature section
menu.add_label(label="📊 Temperatura:", foreground="#FFD700")
for label, temp in TEMP_PRESETS.items():
    menu.add_command(label=label, command=lambda t=temp: set_temperature(t), foreground="white")

menu.add_separator()

# Color section
menu.add_label(label="🎨 Kolor menu:", foreground="#FFD700")
for label, color in COLORS.items():
    menu.add_command(label=label, command=lambda c=color: set_color(c), foreground="white")

menu.add_separator()

# Exit option
menu.add_command(label="❌ Zamknij", command=lambda: root.destroy(), foreground="#FF4444")

# Start tray in top-right corner (minimized)
root.geometry("+1850+10")
root.overrideredirect(True)
root.attributes('-topmost', True)
root.deiconify()

update_tray()

# Handle SIGTERM
def handle_signal(signum, frame):
    root.destroy()
    sys.exit(0)

signal.signal(signal.SIGTERM, handle_signal)
signal.signal(signal.SIGINT, handle_signal)

# Hide window on close
root.protocol("WM_DELETE_WINDOW", on_close)

root.mainloop()
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
  "color": "#FFD700"
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

# Applet service (GUI)
cat > ~/.config/systemd/user/redshift-scheduler-applet.service << 'APPLET_SERVICE'
[Unit]
Description=Redshift Scheduler Applet
PartOf=graphical-session.target
After=graphical-session-pre.target

[Service]
Type=simple
ExecStart=sh -c 'DISPLAY=${DISPLAY:-:0} %h/.local/bin/redshift-scheduler-applet'
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"

[Install]
WantedBy=graphical-session.target
APPLET_SERVICE

echo -e "${GREEN}✅ Service files created${NC}\n"

# ============================================
# 6. FIX SYSTEMD (MX Linux issue)
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
# 7. ENABLE AND START SERVICES
# ============================================
echo -e "${GREEN}✅ Enabling services...${NC}"
systemctl --user enable redshift-scheduler-daemon.service 2>/dev/null || true
systemctl --user enable redshift-scheduler-applet.service 2>/dev/null || true

echo -e "${GREEN}🚀 Starting services...${NC}"
systemctl --user start redshift-scheduler-daemon.service 2>/dev/null || true
systemctl --user start redshift-scheduler-applet.service 2>/dev/null || true

sleep 2

# ============================================
# 8. VERIFY INSTALLATION
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
    echo -e "${YELLOW}⚠️  Processes not running from systemd - trying manual start...${NC}"
    ~/.local/bin/redshift-scheduler-daemon > /dev/null 2>&1 &
    sleep 1
    DISPLAY=:0 ~/.local/bin/redshift-scheduler-applet > /dev/null 2>&1 &
    sleep 2
    RUNNING=$(ps aux | grep -E "redshift-scheduler-(daemon|applet)" | grep -v grep | wc -l)
    if [ $RUNNING -gt 0 ]; then
        echo -e "${GREEN}✅ Manual start successful! Found $RUNNING processes:${NC}"
        ps aux | grep -E "redshift-scheduler-(daemon|applet)" | grep -v grep
    else
        echo -e "${RED}❌ Failed to start - check systemd status${NC}"
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

if [ -f ~/.config/systemd/user/redshift-scheduler-daemon.service ]; then
    echo -e "${GREEN}✅${NC} ~/.config/systemd/user/redshift-scheduler-daemon.service"
else
    echo -e "${RED}❌${NC} ~/.config/systemd/user/redshift-scheduler-daemon.service"
fi

if [ -f ~/.config/systemd/user/redshift-scheduler-applet.service ]; then
    echo -e "${GREEN}✅${NC} ~/.config/systemd/user/redshift-scheduler-applet.service"
else
    echo -e "${RED}❌${NC} ~/.config/systemd/user/redshift-scheduler-applet.service"
fi

# ============================================
# 9. INSTALLATION SUMMARY
# ============================================
echo -e "\n${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ INSTALLATION COMPLETE!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📁 Installed files:${NC}"
echo "  • Daemon:  ~/.local/bin/redshift-scheduler-daemon"
echo "  • Applet:  ~/.local/bin/redshift-scheduler-applet"
echo "  • Config:  ~/.config/redshift-scheduler/config.json"
echo "  • Services: ~/.config/systemd/user/"

echo -e "\n${YELLOW}🎨 Features:${NC}"
echo "  • 🌙 Tray icon dropdown menu (click to show)"
echo "  • 🔄 Toggle ON/OFF directly from menu"
echo "  • 📊 Temperature presets (3000K, 4500K, 6500K)"
echo "  • 🎨 Color themes (Blue, Yellow, Orange, Red)"
echo "  • ⚙️  Auto-start on login"
echo "  • 👻 Minimized window in top-right corner"
echo "  • 🚀 Right-click to close tray"

echo -e "\n${YELLOW}🔧 Useful commands:${NC}"
echo "  • Check daemon:  systemctl --user status redshift-scheduler-daemon"
echo "  • View logs:     journalctl --user -u redshift-scheduler-daemon -f"
echo "  • Edit config:   nano ~/.config/redshift-scheduler/config.json"
echo "  • Manual start:  ~/.local/bin/redshift-scheduler-daemon &"
echo "  • Manual applet: DISPLAY=:0 ~/.local/bin/redshift-scheduler-applet &"
echo "  • Stop services: systemctl --user stop redshift-scheduler-*.service"
echo "  • Restart:       systemctl --user restart redshift-scheduler-*.service"

echo -e "\n${YELLOW}🚀 Usage:${NC}"
echo "  1. ✅ Installation done - tray icon in top-right corner"
echo "  2. Click 🌙 icon to open dropdown menu"
echo "  3. Toggle ON/OFF or change temperature"
echo "  4. Select color theme from menu"
echo "  5. Right-click to close (or just click away)"

echo -e "\n${YELLOW}📦 To reinstall in the future:${NC}"
echo "  bash install.sh"
echo "  (This will automatically clean up old installation)"

echo -e "\n${GREEN}Happy coding! 🚀${NC}\n"

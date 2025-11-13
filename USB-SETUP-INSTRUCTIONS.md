# USB Stick Setup Instructions

Copy `usb-bootstrap.sh` to a USB stick for easy deployment on new Omarchy systems.

## Prepare the USB stick

```bash
# Copy the script to your USB stick
cp usb-bootstrap.sh /path/to/usb/
```

## Use on a fresh Omarchy install

1. **Plug in USB stick**

2. **Run the script:**
   ```bash
   bash /path/to/usb/usb-bootstrap.sh
   ```

3. **Follow the prompts:**
   - SSH key will be created automatically
   - Copy the displayed key to GitHub
   - Press Enter to continue
   - Everything else is automatic!

## What it does

- ✓ Creates SSH keys
- ✓ Guides you through GitHub setup
- ✓ Clones your dotfiles repo
- ✓ Runs bootstrap automatically
- ✓ Applies all rice configs

**Time:** ~2 minutes (including GitHub key setup)

## One command, fully riced system!

After running this script, your new Omarchy install will have:
- Transparent floating Waybar with Cava visualizer
- Rounded corners on all windows
- Performance trackers (CPU/RAM/GPU)
- Terminal fonts optimized for 1440p
- All your configs and keybindings

No manual configuration needed!


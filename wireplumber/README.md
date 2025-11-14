# WirePlumber Configuration

## Wave XLR Workaround

This configuration implements a fix for the Elgato Wave XLR on Linux, based on the unofficial guide at [jmansar.github.io/wavexlr-on-linux-cfg](https://jmansar.github.io/wavexlr-on-linux-cfg/).

### The Problem

The Wave XLR has an issue on Linux where there is no audio signal from the microphone when the device is also used for playback. This occurs because if playback starts before recording, the microphone input fails to initialize properly.

### The Solution

This workaround ensures the microphone capture starts before any playback by:

1. **Disabling the automatic Wave XLR sink** (playback) node creation
2. **Renaming the Wave XLR source** (microphone) to `wavexlr-source`
3. **Creating a virtual null sink** and linking it to the microphone
4. **Only after the link is established**, creating the custom Wave XLR sink for playback

### Files

- `.config/wireplumber/wireplumber.conf.d/51-wavexlr.conf` - Configuration that loads the custom script and renames audio nodes
- `.local/share/wireplumber/scripts/wavexlrfix.lua` - Custom Lua script that manages the initialization sequence

### Audio Devices Created

- **WaveXLR Sink** - Use this for audio output/playback (headphones)
- **Elgato Wave XLR Mono** - Your microphone input
- **Null Sink For WaveXLR Source** - Internal workaround device (do not use)

### Troubleshooting

If you unplug and replug the Wave XLR and the microphone stops working:

```bash
systemctl --user restart wireplumber
```

Or toggle the device profile in `pavucontrol`.

### Verification

Check if the script is working:

```bash
wpctl status  # Should show "WaveXLR Sink" and "Elgato Wave XLR Mono"
journalctl --user -u wireplumber -n 50 | grep wavexlrfix  # Check script logs
```

### Notes

- This workaround is **not officially supported** by Elgato
- It preserves all existing Omarchy audio functionality
- The configuration is managed via GNU Stow like other dotfiles


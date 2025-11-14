#!/bin/bash

# Cava visualizer for Waybar with audio control
# Converts cava raw output to Unicode block characters
# Changes color to red when muted

CONFIG_PATH="$HOME/.config/waybar/scripts/cava-config"

# Unicode block characters from lowest to highest
BLOCKS=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

# Check if cava is installed
if ! command -v cava &> /dev/null; then
    echo '{"text": "󰝚 Cava not installed", "class": "error"}'
    exit 1
fi

# Check if pamixer is installed
if ! command -v pamixer &> /dev/null; then
    echo '{"text": "󰝚 pamixer not installed", "class": "error"}'
    exit 1
fi

# Start cava and process output, redirect stderr to /dev/null
cava -p "$CONFIG_PATH" 2>/dev/null | while IFS= read -r line; do
    # Skip empty lines or lines that aren't numeric data
    if [[ -z "$line" ]] || [[ ! "$line" =~ ^[0-9\ ]+$ ]]; then
        continue
    fi
    
    # Convert space-separated numbers to block characters
    output=""
    for val in $line; do
        # Clamp value between 0-7 and get corresponding block
        if [[ "$val" =~ ^[0-9]+$ ]] && [ "$val" -ge 0 ] && [ "$val" -le 7 ] 2>/dev/null; then
            output+="${BLOCKS[$val]} "
        else
            output+="${BLOCKS[0]} "
        fi
    done
    
    # Only output if we have data
    if [ -n "$output" ]; then
        # Check mute status - pamixer returns "true" or "false" as string
        mute_status=$(pamixer --get-mute 2>/dev/null)
        if [ "$mute_status" = "true" ]; then
            # Muted - add muted class
            echo "{\"text\": \"$output\", \"class\": \"muted\"}"
        else
            # Not muted - normal class
            echo "{\"text\": \"$output\", \"class\": \"normal\"}"
        fi
    fi
done


#!/bin/bash

# Get GPU stats, handle errors gracefully
gpu_stats=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$gpu_stats" ]; then
    # Parse the values
    util=$(echo "$gpu_stats" | awk -F', ' '{print $1}')
    temp=$(echo "$gpu_stats" | awk -F', ' '{print $2}')
    mem_used=$(echo "$gpu_stats" | awk -F', ' '{printf "%.1f", $3/1024}')
    mem_total=$(echo "$gpu_stats" | awk -F', ' '{printf "%.1f", $4/1024}')
    
    echo "GPU: ${util}% | Temp: ${temp}°C | VRAM: ${mem_used}G / ${mem_total}G"
else
    # If nvidia-smi fails, show error message
    echo "GPU: Driver error (try: sudo rmmod nvidia_uvm nvidia_drm nvidia_modeset nvidia && sudo modprobe nvidia)"
fi



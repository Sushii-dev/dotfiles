#!/bin/bash

# Get GPU utilization, handle errors gracefully
gpu_util=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$gpu_util" ]; then
    # Remove any spaces and add percentage sign
    echo "${gpu_util}%"
else
    # If nvidia-smi fails, show N/A
    echo "N/A"
fi



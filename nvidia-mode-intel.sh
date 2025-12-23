#!/bin/bash
# Switch to Intel as primary GPU (hybrid mode with NVIDIA on-demand)

CONFIG_FILE="/usr/share/X11/xorg.conf.d/nvidia-drm-outputclass.conf"

if [ -f "$CONFIG_FILE" ]; then
    echo "Disabling NVIDIA as primary GPU..."
    sudo mv "$CONFIG_FILE" "${CONFIG_FILE}.disabled"
    echo "Intel GPU will be primary after restart."
    echo ""
    echo "Restarting display manager..."
    sudo systemctl restart display-manager
else
    echo "NVIDIA config already disabled. Intel GPU is primary."
fi

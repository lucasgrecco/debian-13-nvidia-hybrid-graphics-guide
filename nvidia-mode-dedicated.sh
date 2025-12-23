#!/bin/bash
# Switch to NVIDIA as primary GPU

CONFIG_FILE="/usr/share/X11/xorg.conf.d/nvidia-drm-outputclass.conf"
DISABLED_FILE="${CONFIG_FILE}.disabled"

if [ -f "$DISABLED_FILE" ]; then
    echo "Enabling NVIDIA as primary GPU..."
    sudo mv "$DISABLED_FILE" "$CONFIG_FILE"
    echo "NVIDIA GPU will be primary after restart."
    echo ""
    echo "Restarting display manager..."
    sudo systemctl restart display-manager
else
    echo "NVIDIA config already enabled. NVIDIA GPU is primary."
fi

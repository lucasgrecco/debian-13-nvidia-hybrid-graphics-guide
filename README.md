# NVIDIA Open Kernel Modules Installation Guide - Debian 13 Trixie
**Complete Step-by-Step Documentation**

## Intro
I created this guide with the help of Claude Code to install the NVIDIA drivers on my Lenovo Legion 5i. After many attempts to use the version provided by Debian, I found that the latest version does not support 50-series graphics cards.

## AI Summary
This document provides a complete, step-by-step guide for installing NVIDIA Open Kernel Modules on Debian 13 (Trixie) for modern RTX GPUs, with a focus on hybrid graphics laptops using Intel and NVIDIA GPUs together. It explains why the NVIDIA drivers shipped by Debian are not sufficient for RTX 50-series cards and documents a manual installation approach using NVIDIA’s open-source kernel modules combined with the proprietary userspace driver.

The guide covers system requirements, kernel and driver compatibility, module compilation and installation, userspace driver setup, Nouveau blacklisting, and post-installation validation. It emphasizes hybrid graphics usage through PRIME Render Offload, showing how to run applications on the NVIDIA GPU only when needed to preserve battery life. It also explains BIOS GPU modes, their trade-offs, and how they interact with the installed driver.

Troubleshooting sections address common issues such as driver loading failures, Secure Boot, and version mismatches, along with clear uninstallation steps and maintenance notes for kernel updates. The document concludes with a practical command reference and external resources, making it a hands-on reference for enabling NVIDIA GPUs on Debian systems where official packages lag behind new hardware support.

## System Information
- **OS:** Debian 13 (Trixie)
- **Kernel:** 6.12.57+deb13-amd64
- **Architecture:** x86_64
- **CPU:** Intel Core Ultra 7 755HX (with integrated graphics)
- **GPU:** NVIDIA GeForce RTX 5070 Max-Q (Mobile)
- **Driver Version:** 590.48.01 (Open Source Kernel Modules)
- **Setup Type:** Hybrid Graphics (Intel + NVIDIA)

---

## Overview

This guide documents the installation of NVIDIA's open-source kernel modules with hybrid graphics support, allowing you to:
- Use Intel GPU by default (better battery life)
- Use NVIDIA GPU on-demand (better performance)
- Switch between GPUs as needed

---

## Prerequisites

### 1. System Requirements
- Linux kernel 4.15 or newer
- Compatible GPU (Turing architecture or newer: RTX 2000/3000/4000/5000 series)
- Build tools and kernel headers

### 2. Download Required Files
- **Open kernel modules source:** Download from [NVIDIA's GitHub](https://github.com/NVIDIA/open-gpu-kernel-modules/releases)
  - File: `open-gpu-kernel-modules-590.48.01.tar.gz` or similar
- **Userspace driver:** Download from [NVIDIA's website](https://www.nvidia.com/download/index.aspx)
  - File: `NVIDIA-Linux-x86_64-590.48.01.run`

---

## Installation Steps

### Step 1: Install Prerequisites

Update package lists and install required tools:

```bash
sudo apt update
sudo apt install linux-headers-$(uname -r)
sudo apt install build-essential dkms
```

Verify kernel headers installation:
```bash
ls /usr/src/linux-headers-$(uname -r)
```

### Step 2: Remove Existing NVIDIA Drivers

Remove any previously installed NVIDIA packages:

```bash
sudo apt remove --purge '^nvidia-.*'
sudo apt remove --purge '^libnvidia-.*'
sudo apt autoremove
```

### Step 3: Extract and Build Kernel Modules

Navigate to the downloaded source directory:
```bash
cd ~/Downloads/open-gpu-kernel-modules-590.48.01
```

Build the kernel modules (takes 5-10 minutes):
```bash
make modules -j$(nproc)
```

**Expected output:**
- Compilation messages showing builds for nvidia.ko, nvidia-drm.ko, nvidia-modeset.ko, nvidia-uvm.ko
- "Nothing to be done" if already compiled

Verify modules were built:
```bash
find kernel-open -name "*.ko" -type f
```

Should show:
- nvidia.ko
- nvidia-drm.ko
- nvidia-modeset.ko
- nvidia-uvm.ko
- nvidia-peermem.ko

### Step 4: Install Kernel Modules

Install the compiled modules to the system:
```bash
sudo make modules_install -j$(nproc)
sudo depmod -a
```

**Note:** You may see SSL errors about signing keys - these are normal if Secure Boot is disabled or signing keys aren't configured. The modules will still install correctly.

Verify installation:
```bash
ls -lh /lib/modules/$(uname -r)/kernel/drivers/video/nvidia*.ko.xz
```

### Step 5: Download Userspace Driver

Download the matching version userspace driver:

**Option A - Using wget:**
```bash
cd ~/Downloads
wget https://us.download.nvidia.com/XFree86/Linux-x86_64/590.48.01/NVIDIA-Linux-x86_64-590.48.01.run
chmod +x NVIDIA-Linux-x86_64-590.48.01.run
```

**Option B - Manual download:**
1. Visit: https://www.nvidia.com/download/index.aspx
2. Select your GPU model and Linux 64-bit
3. Download version 590.48.01
4. Make it executable: `chmod +x NVIDIA-Linux-*.run`

### Step 6: Install Userspace Components

Run the installer with the `--no-kernel-modules` flag:
```bash
cd ~/Downloads
sudo ./NVIDIA-Linux-x86_64-590.48.01.run --no-kernel-modules
```

**Interactive Prompts and Responses:**

1. **Kernel module type:**
   - Choose: `MIT/GPL` (open source)
   - This matches the open-source modules you built

2. **X server running warning:**
   - Choose: `Continue installation`
   - Safe to continue; we'll reboot afterward

3. **No kernel modules warning:**
   - Choose: `OK`
   - Expected; we already installed kernel modules separately

4. **32-bit compatibility libraries:**
   - Choose: `OK`
   - Not critical; skip if not needed

5. **libglvnd EGL vendor library warning:**
   - Choose: `OK`
   - Not critical for basic functionality

6. **Run nvidia-xconfig utility:**
   - **For Hybrid Graphics:** Choose `No`
   - **For NVIDIA-only:** Choose `Yes`
   - We chose `No` for better battery life and GPU switching

### Step 7: Blacklist Nouveau Driver

The open-source Nouveau driver must be disabled:

```bash
sudo bash -c "echo 'blacklist nouveau' > /etc/modprobe.d/blacklist-nouveau.conf"
sudo bash -c "echo 'options nouveau modeset=0' >> /etc/modprobe.d/blacklist-nouveau.conf"
```

Update initramfs:
```bash
sudo update-initramfs -u
```

Verify configuration:
```bash
cat /etc/modprobe.d/blacklist-nouveau.conf
```

Should show:
```
blacklist nouveau
options nouveau modeset=0
```

### Step 8: Reboot

Reboot to load the new driver:
```bash
sudo reboot
```

---

## Post-Installation Verification

After reboot, verify the installation:

### 1. Check Driver Version
```bash
nvidia-smi
```

**Expected output:**
- Driver Version: 590.48.01
- GPU detected: GeForce RTX 5070
- Memory: 8151 MiB total

### 2. Check Loaded Kernel Modules
```bash
lsmod | grep nvidia
```

**Should show:**
- nvidia
- nvidia_drm
- nvidia_modeset
- nvidia_uvm
- nvidia_peermem (optional)

### 3. Check GPU Detection
```bash
nvidia-smi -L
```

Should list your GPU.

### 4. Check System Logs (if issues)
```bash
sudo dmesg | grep -i nvidia
```

Look for any errors or warnings.

---

## Hybrid Graphics Usage (PRIME Render Offload)

### Default Behavior
- **Intel GPU:** Used by default for all applications (saves battery)
- **NVIDIA GPU:** Available on-demand for specific applications

### Using NVIDIA GPU for Specific Applications

Run any application with NVIDIA GPU using environment variables:

```bash
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia your-application
```

**Examples:**

Run glxgears with NVIDIA:
```bash
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxgears
```

Run a game with NVIDIA:
```bash
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia steam
```

### Creating a Convenient Alias (Recommended)

Add an alias to your `.bashrc` for easy NVIDIA usage:

```bash
echo "" >> ~/.bashrc
echo "# NVIDIA GPU alias for hybrid graphics" >> ~/.bashrc
echo "alias nvidia='__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia'" >> ~/.bashrc
```

Reload your bashrc:
```bash
source ~/.bashrc
```

**Usage:**
```bash
nvidia glxgears
nvidia steam
nvidia your-application
```

Much simpler than typing the full environment variables every time!

### Alternative: Creating a Helper Script

If you prefer a script instead of an alias, create a wrapper:

```bash
sudo nano /usr/local/bin/nvidia-run
```

Add this content:
```bash
#!/bin/bash
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia "$@"
```

Make it executable:
```bash
sudo chmod +x /usr/local/bin/nvidia-run
```

**Usage:**
```bash
nvidia-run your-application
```

### Verifying Which GPU is Being Used

Install mesa-utils:
```bash
sudo apt install mesa-utils
```

Check default GPU (Intel):
```bash
glxinfo | grep "OpenGL renderer"
```

Check with NVIDIA:
```bash
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo | grep "OpenGL renderer"
```

---

## BIOS GPU Mode Settings

Your laptop BIOS has three GPU mode options. Here's how each affects your setup:

### Option 1: Hybrid/Switchable Graphics (Current Setup)
**BIOS Setting:** Hybrid VGA / Switchable Graphics / Optimus

**Behavior:**
- Both Intel and NVIDIA GPUs are active
- Intel GPU handles display by default (saves battery)
- NVIDIA GPU available on-demand via PRIME Render Offload
- Use `nvidia command` to run apps on NVIDIA

**Pros:**
- ✓ Best battery life
- ✓ Flexibility to choose GPU per application
- ✓ Lower temperatures when idle

**Cons:**
- ✗ Requires manual selection for NVIDIA apps
- ✗ Slightly more complex setup

**When to use:** Daily use, battery-powered scenarios, mixed workloads

### Option 2: Dedicated/Discrete Only
**BIOS Setting:** Discrete Graphics / Dedicated GPU Only / NVIDIA Only

**Behavior:**
- Only NVIDIA GPU is active
- Intel GPU is completely disabled by BIOS
- All applications automatically use NVIDIA
- No need for PRIME Render Offload commands
- X server directly uses NVIDIA

**Pros:**
- ✓ Maximum performance always
- ✓ No need to use `nvidia` command
- ✓ Simpler - everything uses NVIDIA automatically

**Cons:**
- ✗ Significantly worse battery life
- ✗ Higher power consumption and heat
- ✗ No power saving when idle

**When to use:** Plugged in, gaming sessions, intensive GPU work

**Driver compatibility:** ✅ **Yes, your NVIDIA driver will work perfectly in this mode!** In fact, it's simpler since everything uses NVIDIA by default.

### Option 3: Integrated Only
**BIOS Setting:** Integrated Graphics / iGPU Only

**Behavior:**
- Only Intel GPU is active
- NVIDIA GPU is completely disabled by BIOS
- NVIDIA driver won't be used
- Maximum battery life

**Pros:**
- ✓ Best battery life
- ✓ Lowest power consumption
- ✓ Coolest temperatures

**Cons:**
- ✗ No GPU acceleration for heavy tasks
- ✗ NVIDIA driver inactive

**When to use:** Maximum battery life needed, light workloads only

**Driver compatibility:** ⚠️ NVIDIA driver installed but unused (harmless)

### Switching Between Modes

To change GPU mode:
1. Restart your laptop
2. Enter BIOS (usually F2, F10, DEL, or ESC during boot)
3. Find "Graphics Configuration" or "GPU Mode" setting
4. Select desired mode
5. Save and exit

**No driver reconfiguration needed!** Your NVIDIA installation works with all three modes.

### Recommended Mode

**For most laptop users:** Hybrid mode (current setup)
- Use `nvidia` command when you need performance
- Enjoy battery life when you don't

**For desktop replacement/always plugged in:** Dedicated mode
- Always maximum performance
- No manual GPU selection needed

---

## Troubleshooting

### Driver Not Loading

**Check kernel modules:**
```bash
lsmod | grep nvidia
```

**Manually load modules:**
```bash
sudo modprobe nvidia
sudo modprobe nvidia_drm
sudo modprobe nvidia_modeset
```

**Check for errors:**
```bash
sudo dmesg | grep -i nvidia | grep -i error
```

### nvidia-smi Not Working

**Check if driver is loaded:**
```bash
lsmod | grep nvidia
```

**Verify installation:**
```bash
which nvidia-smi
nvidia-smi --version
```

### Secure Boot Issues

If you have Secure Boot enabled, you may need to:

1. **Disable Secure Boot in BIOS**, or
2. **Sign the kernel modules:**
   ```bash
   sudo /usr/src/linux-headers-$(uname -r)/scripts/sign-file sha256 \
     /path/to/signing_key.pem \
     /path/to/signing_key.x509 \
     /lib/modules/$(uname -r)/kernel/drivers/video/nvidia.ko
   ```

### Version Mismatch Errors

Ensure kernel modules and userspace driver versions match:
```bash
cat /proc/driver/nvidia/version
nvidia-smi --version
```

Both should show: 590.48.01

### Performance Issues

**Force NVIDIA for entire X session (not recommended for laptops):**

Create `/etc/X11/xorg.conf`:
```bash
sudo nvidia-xconfig
```

This will use NVIDIA exclusively but reduce battery life.

---

## Uninstallation

If you need to remove the driver:

### 1. Remove Userspace Components
Run the original installer with uninstall flag:
```bash
sudo ./NVIDIA-Linux-x86_64-590.48.01.run --uninstall
```

### 2. Remove Kernel Modules
```bash
cd ~/Downloads/open-gpu-kernel-modules-590.48.01
sudo rm /lib/modules/$(uname -r)/kernel/drivers/video/nvidia*.ko.xz
sudo depmod -a
```

### 3. Remove Nouveau Blacklist
```bash
sudo rm /etc/modprobe.d/blacklist-nouveau.conf
sudo update-initramfs -u
```

### 4. Reboot
```bash
sudo reboot
```

---

## Important Notes

### Driver Version Compatibility
- This guide uses driver version 590.48.01
- RTX 5070 is a very new GPU (2025) - version 590.48.01 is from 2022
- If you encounter issues, consider using a newer driver (560+ series)

### Secure Boot
- If Secure Boot is enabled, modules must be signed
- Alternatively, disable Secure Boot in BIOS

### Updates
- Kernel updates may require rebuilding/reinstalling modules
- Keep the source directory for future rebuilds

### Battery Life
- Intel GPU uses significantly less power than NVIDIA
- Use NVIDIA only when needed for performance
- Monitor power usage with `powertop`

---

## Useful Commands Reference

### Driver Information
```bash
nvidia-smi                          # Show GPU status
nvidia-smi -L                       # List GPUs
nvidia-smi -q                       # Detailed info
cat /proc/driver/nvidia/version     # Driver version
```

### Module Management
```bash
lsmod | grep nvidia                 # List loaded modules
sudo modprobe nvidia                # Load nvidia module
sudo modprobe -r nvidia             # Unload nvidia module
```

### System Information
```bash
lspci | grep -i vga                 # List graphics cards
lspci | grep -i nvidia              # List NVIDIA devices
glxinfo | grep "OpenGL renderer"    # Current GPU renderer
```

### Logs and Debugging
```bash
sudo dmesg | grep -i nvidia         # Kernel messages
sudo journalctl -b | grep -i nvidia # System logs
nvidia-smi dmon                     # GPU monitoring
```

---

## Additional Resources

- **NVIDIA Open GPU Kernel Modules:** https://github.com/NVIDIA/open-gpu-kernel-modules
- **NVIDIA Driver Downloads:** https://www.nvidia.com/download/index.aspx
- **NVIDIA Linux Documentation:** https://download.nvidia.com/XFree86/Linux-x86_64/
- **Debian Wiki - NVIDIA:** https://wiki.debian.org/NvidiaGraphicsDrivers
- **PRIME Render Offload:** https://download.nvidia.com/XFree86/Linux-x86_64/435.17/README/primerenderoffload.html

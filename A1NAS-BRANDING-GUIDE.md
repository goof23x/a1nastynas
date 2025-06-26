# A1NAS Custom Branding & Boot Guide

## 🚀 Professional Custom Boot Experience

This guide covers the complete A1NAS custom branding and boot system that provides a professional, multi-option boot experience for your Network Attached Storage OS.

## 📋 What's Included

### ✅ Custom Build Script
- **`a1nas-branded-boot.sh`** - Main build script with professional branding
- Supports both GRUB and ISOLINUX bootloaders
- Automated system configuration with A1NAS theming

### ✅ GRUB Configuration
- **`config/grub/grub.cfg`** - Professional GRUB menu with multiple boot options
- **`config/grub/themes/a1nas/theme.txt`** - Custom theme with cyan/blue color scheme
- Multiple boot modes: Live, Performance, Debug, Safe, Recovery
- Advanced options and system tools submenus

### ✅ ISOLINUX Configuration
- **`config/isolinux/isolinux.cfg`** - Enhanced ISOLINUX menu with branding
- Professional color scheme and ASCII art
- Comprehensive help text for each boot option
- Automatic splash screen generation

## 🎯 Features

### 🎨 Professional Branding
- Custom ASCII art A1NAS logo
- Consistent cyan/blue color scheme
- Professional system messages and prompts
- Branded user experience throughout

### 🚀 Multiple Boot Options
1. **Live Mode (Default)** - Standard boot with full desktop
2. **Performance Mode** - Optimized for high-performance workloads
3. **Debug Mode** - Verbose logging for troubleshooting
4. **Safe Mode** - Minimal drivers for compatibility
5. **Persistent Storage** - Saves changes between reboots
6. **Recovery Mode** - Single-user mode for system repair

### 🛠️ Advanced Features
- Text-only mode for headless operation
- Memory testing capabilities
- Hardware detection tools
- Network diagnostics
- System recovery options

## 📖 Usage Instructions

### Prerequisites
Install required packages:
```bash
sudo apt-get update
sudo apt-get install debootstrap squashfs-tools genisoimage xorriso \
                     grub-pc-bin grub-efi-amd64-bin imagemagick
```

### Building with GRUB (Recommended)
```bash
# Make script executable
chmod +x a1nas-branded-boot.sh

# Build with GRUB bootloader
sudo ./a1nas-branded-boot.sh grub
```

### Building with ISOLINUX
```bash
# Build with ISOLINUX bootloader
sudo ./a1nas-branded-boot.sh isolinux
```

### Default Behavior
If no bootloader is specified, GRUB is used by default:
```bash
sudo ./a1nas-branded-boot.sh
```

## 🎮 Boot Menu Options

### 🚀 Main Boot Options

| Option | Description | Use Case |
|--------|-------------|----------|
| **Live Mode** | Standard boot with full desktop | General use, testing |
| **Performance Mode** | Optimized for high performance | Storage workloads, servers |
| **Debug Mode** | Verbose logging enabled | Troubleshooting, development |
| **Safe Mode** | Minimal drivers, safe boot | Hardware compatibility issues |
| **Persistent Storage** | Saves changes to disk | Permanent installations |
| **Recovery Mode** | Single-user emergency mode | System repair, recovery |

### 🔬 Advanced Options

| Option | Description | Use Case |
|--------|-------------|----------|
| **Text Mode Only** | No graphical interface | Headless servers, low resources |
| **Network Boot Check** | Network diagnostics | Network troubleshooting |
| **Memory Test** | Memtest86+ memory testing | Hardware validation |

### 🛠️ System Tools

| Tool | Description | Use Case |
|------|-------------|----------|
| **Hardware Detection** | Comprehensive hardware scan | Driver issues, compatibility |
| **Disk Utility Mode** | Disk management tools | Storage configuration |

## 🎨 Customization Options

### Modifying Boot Options
Edit the configuration files to add or modify boot options:

**For GRUB:**
```bash
nano config/grub/grub.cfg
```

**For ISOLINUX:**
```bash
nano config/isolinux/isolinux.cfg
```

### Changing Color Scheme
Modify the color definitions in the respective configuration files:

**GRUB Colors:**
```
set color_normal=cyan/black
set color_highlight=white/blue
```

**ISOLINUX Colors:**
```
MENU COLOR sel            7;37;40    #e0ffffff #20ff0000 all
MENU COLOR unsel          37;44      #50ffffff #00000000 std
```

### Custom Branding
1. Replace ASCII art in configuration files
2. Modify welcome messages and help text
3. Update system version and branding strings
4. Customize background images and themes

## 🔧 Technical Details

### Build Process
1. **System Creation** - Creates minimal Ubuntu base system
2. **Branding Application** - Applies custom A1NAS theming
3. **User Configuration** - Sets up branded user experience
4. **Bootloader Setup** - Configures chosen bootloader with custom menus
5. **ISO Generation** - Creates bootable ISO with hybrid USB support

### System Specifications
- **Base System:** Ubuntu 22.04 LTS (Jammy)
- **Architecture:** AMD64 (x86_64)
- **Boot Support:** UEFI and Legacy BIOS
- **Media Support:** DVD and USB bootable
- **File System:** SquashFS for compression

### Generated Files
- **ISO File:** `a1nas-branded-YYYYMMDD-HHMMSS.iso`
- **Build Directory:** `branded-build/`
- **Boot Assets:** Custom themes, fonts, and graphics

## 🎯 Boot Parameters

### Standard Parameters
- `boot=live` - Live system boot
- `components` - Enable live-boot components
- `quiet splash` - Quiet boot with splash screen
- `toram` - Load system into RAM for faster operation

### Performance Parameters
- `acpi_osi=Linux` - ACPI optimization
- `pcie_aspm=off` - Disable PCIe power management
- `processor.max_cstate=1` - Limit CPU power states
- `idle=poll` - Prevent CPU idle states

### Debug Parameters
- `debug` - Enable debug mode
- `systemd.log_level=debug` - Verbose systemd logging
- `console=tty0 console=ttyS0,115200n8` - Multiple console output

### Safe Mode Parameters
- `nomodeset` - Disable graphics acceleration
- `acpi=off` - Disable ACPI
- `noapic` - Disable APIC
- `nosmp` - Single processor mode

## 🚀 Quick Start

### 1. Prepare Environment
```bash
# Install dependencies
sudo apt-get install debootstrap squashfs-tools genisoimage xorriso \
                     grub-pc-bin grub-efi-amd64-bin imagemagick

# Clone or download the A1NAS files
# Make sure you have the a1nas-branded-boot.sh script
```

### 2. Build Your Custom OS
```bash
# Make executable
chmod +x a1nas-branded-boot.sh

# Build with GRUB (recommended)
sudo ./a1nas-branded-boot.sh grub

# Or build with ISOLINUX
sudo ./a1nas-branded-boot.sh isolinux
```

### 3. Use Your Custom ISO
```bash
# Write to USB drive (replace /dev/sdX with your USB device)
sudo dd if=a1nas-branded-*.iso of=/dev/sdX bs=4M status=progress

# Or burn to DVD using your preferred burning software
```

### 4. Boot Your System
1. Boot from USB/DVD
2. Select your preferred boot option
3. Enjoy your professionally branded A1NAS experience!

## 🎉 Results

After successful build, you'll have:

- ✅ Professional A1NAS branded boot experience
- ✅ Multiple boot options for different use cases
- ✅ Custom themed user interface
- ✅ UEFI/BIOS compatible bootable media
- ✅ USB/DVD hybrid bootable ISO
- ✅ Comprehensive help and documentation built-in

## 🆘 Troubleshooting

### Common Issues

**Build fails with missing packages:**
```bash
sudo apt-get update
sudo apt-get install debootstrap squashfs-tools genisoimage xorriso
```

**GRUB build fails:**
```bash
sudo apt-get install grub-pc-bin grub-efi-amd64-bin
```

**Background images not generated:**
```bash
sudo apt-get install imagemagick
```

**Permission errors:**
```bash
# Always run the build script with sudo
sudo ./a1nas-branded-boot.sh grub
```

### Boot Issues

**System doesn't boot:**
- Try different boot options (Safe Mode, Debug Mode)
- Check BIOS/UEFI settings
- Verify ISO integrity

**Graphics issues:**
- Use Safe Mode (nomodeset)
- Try Text Mode Only
- Check hardware compatibility

**Network issues:**
- Use Network Boot Check option
- Check cable connections
- Verify network configuration

## 📞 Support

For additional support and customization:
- Check the built-in help system (❓ Boot Help & Information)
- Use Debug Mode for detailed logging
- Consult the configuration files in the `config/` directory

---

**🚀 Welcome to A1NAS - The Future of Network Storage!**
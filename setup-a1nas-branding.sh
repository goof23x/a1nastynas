#!/bin/bash
# A1NAS Branding Setup Script
# Quick setup and demonstration of the custom branding system

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}"
cat << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║              A1NAS BRANDING SETUP & DEMO                      ║
║                   Quick Start Guide                           ║
╚════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${BLUE}🚀 Welcome to A1NAS Custom Branding Setup!${NC}"
echo ""
echo "This script will help you set up and demonstrate the A1NAS"
echo "custom branding and boot system with professional theming."
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}❌ Don't run this setup script as root!${NC}"
    echo "Run it as a regular user - it will ask for sudo when needed."
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
missing_packages=()

# Check for required commands
required_commands=("debootstrap" "mksquashfs" "genisoimage" "xorriso")
for cmd in "${required_commands[@]}"; do
    if ! command_exists "$cmd"; then
        case "$cmd" in
            "debootstrap") missing_packages+=("debootstrap") ;;
            "mksquashfs") missing_packages+=("squashfs-tools") ;;
            "genisoimage") missing_packages+=("genisoimage") ;;
            "xorriso") missing_packages+=("xorriso") ;;
        esac
    fi
done

# Check for GRUB tools
if ! command_exists "grub-mkrescue"; then
    missing_packages+=("grub-pc-bin" "grub-efi-amd64-bin")
fi

# Check for ImageMagick
if ! command_exists "convert"; then
    missing_packages+=("imagemagick")
fi

if [[ ${#missing_packages[@]} -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  Missing packages detected: ${missing_packages[*]}${NC}"
    echo ""
    echo "Installing required packages..."
    sudo apt-get update
    sudo apt-get install -y "${missing_packages[@]}"
    echo -e "${GREEN}✅ Packages installed successfully!${NC}"
else
    echo -e "${GREEN}✅ All prerequisites satisfied!${NC}"
fi

echo ""

# Show available options
echo -e "${CYAN}🎯 Available Build Options:${NC}"
echo ""
echo -e "${YELLOW}1.${NC} ${GREEN}GRUB Bootloader${NC} (Recommended)"
echo "   • Modern UEFI/BIOS support"
echo "   • Advanced theming capabilities"
echo "   • Professional menu system"
echo ""
echo -e "${YELLOW}2.${NC} ${GREEN}ISOLINUX Bootloader${NC}"
echo "   • Classic compatibility"
echo "   • Lightweight and fast"
echo "   • Works on older systems"
echo ""
echo -e "${YELLOW}3.${NC} ${GREEN}Demo Mode${NC}"
echo "   • Show configuration files"
echo "   • Explain features without building"
echo ""

# Get user choice
while true; do
    echo -n -e "${BLUE}Choose an option (1-3): ${NC}"
    read -r choice
    case $choice in
        1)
            BOOTLOADER="grub"
            break
            ;;
        2)
            BOOTLOADER="isolinux"
            break
            ;;
        3)
            echo -e "${CYAN}📖 Demo Mode - Showing A1NAS Branding Features${NC}"
            echo ""
            echo -e "${GREEN}🎨 Branding Features:${NC}"
            echo "• Custom ASCII art logos"
            echo "• Professional cyan/blue color scheme"
            echo "• Multiple boot options with descriptions"
            echo "• Branded user experience"
            echo "• Custom system messages"
            echo ""
            echo -e "${GREEN}🚀 Boot Options Available:${NC}"
            echo "• Live Mode (Default) - Full desktop experience"
            echo "• Performance Mode - Optimized for storage workloads"
            echo "• Debug Mode - Verbose logging for troubleshooting"
            echo "• Safe Mode - Minimal drivers for compatibility"
            echo "• Persistent Storage - Save changes between boots"
            echo "• Recovery Mode - System repair and recovery"
            echo ""
            echo -e "${GREEN}📁 Configuration Files:${NC}"
            if [[ -f "config/grub/grub.cfg" ]]; then
                echo "✅ GRUB configuration: config/grub/grub.cfg"
            else
                echo "❌ GRUB configuration not found"
            fi
            if [[ -f "config/isolinux/isolinux.cfg" ]]; then
                echo "✅ ISOLINUX configuration: config/isolinux/isolinux.cfg"
            else
                echo "❌ ISOLINUX configuration not found"
            fi
            if [[ -f "a1nas-branded-boot.sh" ]]; then
                echo "✅ Main build script: a1nas-branded-boot.sh"
            else
                echo "❌ Main build script not found"
            fi
            echo ""
            echo -e "${BLUE}To build your custom A1NAS ISO:${NC}"
            echo "sudo ./a1nas-branded-boot.sh grub    # For GRUB"
            echo "sudo ./a1nas-branded-boot.sh isolinux # For ISOLINUX"
            echo ""
            echo -e "${GREEN}Demo complete! Check the A1NAS-BRANDING-GUIDE.md for full documentation.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid choice. Please enter 1, 2, or 3.${NC}"
            ;;
    esac
done

echo ""
echo -e "${YELLOW}⚠️  Building A1NAS with ${BOOTLOADER^^} bootloader...${NC}"
echo ""
echo "This process will:"
echo "• Create a minimal Ubuntu-based system"
echo "• Apply A1NAS custom branding"
echo "• Configure professional boot menus"
echo "• Generate a bootable ISO file"
echo ""
echo "The build process may take 10-30 minutes depending on your system."
echo "You'll need sudo privileges and about 2GB of free space."
echo ""

# Confirm before proceeding
while true; do
    echo -n -e "${BLUE}Proceed with the build? (y/n): ${NC}"
    read -r confirm
    case $confirm in
        [Yy]*)
            break
            ;;
        [Nn]*)
            echo -e "${YELLOW}Build cancelled.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Please answer yes (y) or no (n).${NC}"
            ;;
    esac
done

echo ""
echo -e "${GREEN}🚀 Starting A1NAS branded build...${NC}"
echo ""

# Check if build script exists
if [[ ! -f "a1nas-branded-boot.sh" ]]; then
    echo -e "${RED}❌ Build script 'a1nas-branded-boot.sh' not found!${NC}"
    echo "Make sure you're in the correct directory with all A1NAS files."
    exit 1
fi

# Make sure script is executable
chmod +x a1nas-branded-boot.sh

# Run the build
if sudo ./a1nas-branded-boot.sh "$BOOTLOADER"; then
    echo ""
    echo -e "${GREEN}🎉 A1NAS branded ISO build completed successfully!${NC}"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "1. Find your ISO file: a1nas-branded-*.iso"
    echo "2. Write to USB: sudo dd if=a1nas-branded-*.iso of=/dev/sdX bs=4M"
    echo "3. Boot and enjoy your custom A1NAS experience!"
    echo ""
    echo -e "${BLUE}💡 Pro Tips:${NC}"
    echo "• Use Performance Mode for storage servers"
    echo "• Use Debug Mode for troubleshooting"
    echo "• Use Safe Mode if you have hardware issues"
    echo ""
    echo -e "${GREEN}🚀 Welcome to the future of Network Storage!${NC}"
else
    echo ""
    echo -e "${RED}❌ Build failed. Check the error messages above.${NC}"
    echo ""
    echo -e "${BLUE}Common solutions:${NC}"
    echo "• Make sure you have enough disk space (2GB+)"
    echo "• Check internet connection for package downloads"
    echo "• Try running with more verbose output for debugging"
    echo ""
    exit 1
fi
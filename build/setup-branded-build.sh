#!/bin/bash
# A1NAS Build Integration Script
# Adds professional branding to your existing A1NAS build system

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
╔══════════════════════════════════════════════════════════════════╗
║              A1NAS BUILD INTEGRATION SETUP                      ║
║          Adding Professional Branding to Your Build             ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${GREEN}🎯 Welcome to A1NAS Professional Branding Integration!${NC}"
echo ""
echo "This script will integrate professional custom branding into your"
echo "existing A1NAS build system that created A1nas-firstboot-v1.2.0-Final.iso"
echo ""

# Check if we're in the right directory
if [[ ! -f "build_live_iso_enhanced.sh" || ! -f "../config/grub/grub.cfg" ]]; then
    echo -e "${RED}❌ Error: Please run this script from the build/ directory${NC}"
    echo "   Make sure you have the enhanced build script and config files."
    exit 1
fi

echo -e "${BLUE}📋 What this integration provides:${NC}"
echo "  ✅ Professional boot menu with A1NAS branding"
echo "  ✅ Multiple boot modes (Live, Performance, Debug, Safe, Recovery)"
echo "  ✅ Enhanced user experience with custom colors and ASCII art"
echo "  ✅ Compatible with your existing A1nas-firstboot system"
echo "  ✅ Keeps all your current functionality intact"
echo ""

# Show current vs new comparison
echo -e "${YELLOW}🔄 Current vs Enhanced:${NC}"
echo ""
echo -e "${BLUE}Current (A1nas-firstboot-v1.2.0):${NC}"
echo "  • Standard Ubuntu live boot menu"
echo "  • Basic functionality"
echo "  • Limited boot options"
echo ""
echo -e "${GREEN}Enhanced (A1NAS Professional):${NC}"
echo "  • Branded A1NAS boot experience"
echo "  • Multiple optimized boot modes"
echo "  • Professional user interface"
echo "  • Enhanced system branding throughout"
echo ""

# Get user confirmation
while true; do
    echo -n -e "${BLUE}Do you want to proceed with the integration? (y/n): ${NC}"
    read -r confirm
    case $confirm in
        [Yy]*)
            break
            ;;
        [Nn]*)
            echo -e "${YELLOW}Integration cancelled. Your existing build system remains unchanged.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Please answer yes (y) or no (n).${NC}"
            ;;
    esac
done

echo ""
echo -e "${CYAN}🚀 Integrating A1NAS Professional Branding...${NC}"
echo ""

# Verify the enhanced build script exists
if [[ ! -f "build_live_iso_branded.sh" ]]; then
    echo -e "${RED}❌ Enhanced build script not found: build_live_iso_branded.sh${NC}"
    echo "   Please make sure all branding files are in place."
    exit 1
fi

# Check if config files exist
if [[ ! -f "../config/grub/grub.cfg" || ! -f "../config/isolinux/isolinux.cfg" ]]; then
    echo -e "${RED}❌ Branding configuration files not found in ../config/${NC}"
    echo "   Please make sure the GRUB and ISOLINUX configs are installed."
    exit 1
fi

echo -e "${GREEN}✅ All required files found!${NC}"
echo ""

# Show available build options
echo -e "${CYAN}🎯 Available Build Options:${NC}"
echo ""
echo -e "${YELLOW}1.${NC} ${GREEN}Enhanced Branded Build${NC} (Recommended)"
echo "   • Uses your enhanced build script with professional branding"
echo "   • Maintains compatibility with A1nas-firstboot functionality"
echo "   • Adds professional boot menu and user experience"
echo ""
echo -e "${YELLOW}2.${NC} ${GREEN}Original Build with Branding Config${NC}"
echo "   • Uses your original build_live_iso_enhanced.sh"
echo "   • Benefits from the enhanced GRUB/ISOLINUX configurations"
echo "   • Lighter integration approach"
echo ""

# Get build choice
while true; do
    echo -n -e "${BLUE}Choose build option (1-2): ${NC}"
    read -r choice
    case $choice in
        1)
            BUILD_SCRIPT="build_live_iso_branded.sh"
            BUILD_TYPE="Enhanced Branded"
            break
            ;;
        2)
            BUILD_SCRIPT="build_live_iso_enhanced.sh"
            BUILD_TYPE="Original Enhanced"
            break
            ;;
        *)
            echo -e "${RED}❌ Invalid choice. Please enter 1 or 2.${NC}"
            ;;
    esac
done

echo ""
echo -e "${YELLOW}⚙️  Selected: ${BUILD_TYPE} Build${NC}"
echo -e "${BLUE}   Script: ${BUILD_SCRIPT}${NC}"
echo ""

# Final confirmation
echo -e "${YELLOW}📋 Ready to build A1NAS with professional branding!${NC}"
echo ""
echo "This will:"
echo "  • Use the ${BUILD_TYPE} build process"
echo "  • Apply professional A1NAS branding"
echo "  • Create a new ISO with enhanced boot experience"
echo "  • Preserve all existing A1NAS functionality"
echo ""

while true; do
    echo -n -e "${BLUE}Start the build now? (y/n): ${NC}"
    read -r start_build
    case $start_build in
        [Yy]*)
            break
            ;;
        [Nn]*)
            echo -e "${YELLOW}Build preparation complete. Run when ready:${NC}"
            echo -e "${GREEN}   sudo ./${BUILD_SCRIPT}${NC}"
            echo ""
            echo -e "${CYAN}Your A1NAS build system is now ready for professional branding!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Please answer yes (y) or no (n).${NC}"
            ;;
    esac
done

echo ""
echo -e "${GREEN}🚀 Starting A1NAS branded build process...${NC}"
echo ""

# Check for sudo
if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}⚠️  This script needs to run the build as root.${NC}"
    echo "   Executing: sudo ./${BUILD_SCRIPT}"
    echo ""
    
    # Run the build script with sudo
    if sudo "./${BUILD_SCRIPT}"; then
        echo ""
        echo -e "${GREEN}🎉 A1NAS Professional Branded Build Complete!${NC}"
        echo ""
        echo -e "${CYAN}📁 Your new branded ISO should be available in the project root.${NC}"
        echo -e "${BLUE}   Look for: A1nas-branded-*.iso${NC}"
        echo ""
        echo -e "${YELLOW}🚀 Next Steps:${NC}"
        echo "   1. Test the new ISO in a virtual machine"
        echo "   2. Verify the professional boot menu works"
        echo "   3. Confirm all A1NAS functionality is preserved"
        echo "   4. Deploy your professionally branded A1NAS!"
        echo ""
        echo -e "${GREEN}✨ Your A1NAS is now professionally branded and ready!${NC}"
    else
        echo ""
        echo -e "${RED}❌ Build failed. Please check the error messages above.${NC}"
        echo ""
        echo -e "${BLUE}💡 Troubleshooting tips:${NC}"
        echo "   • Make sure you have enough disk space (2GB+)"
        echo "   • Check internet connection for package downloads"
        echo "   • Verify all configuration files are present"
        echo "   • Review the build log for specific errors"
        exit 1
    fi
else
    # Already running as root
    if "./${BUILD_SCRIPT}"; then
        echo ""
        echo -e "${GREEN}🎉 A1NAS Professional Branded Build Complete!${NC}"
        echo ""
        echo -e "${CYAN}Your professional A1NAS ISO is ready!${NC}"
    else
        echo ""
        echo -e "${RED}❌ Build failed. Please check the error messages above.${NC}"
        exit 1
    fi
fi
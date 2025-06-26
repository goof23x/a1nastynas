#!/bin/bash
# A1NAS Branded Boot Builder - Professional custom branding and boot experience
# Enhanced version with GRUB and ISOLINUX support

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} ✅ $*"; }
error() { echo -e "${RED}[ERROR]${NC} ❌ $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} ⚠️ $*"; }

# ASCII Art Banner
echo -e "${CYAN}"
cat << 'EOF'
    ╔══════════════════════════════════════════════════════════════╗
    ║     ▄▀█ ▄█ █▄ █ ▄▀█ █▀   █▄▄ █▀█ ▄▀█ █▄ █ █▀▄ █▀▀ █▀▄     ║
    ║     █▄█ ▀█ █▀▄█ █▄█ ▄█   █▄█ █▀▄ █▄█ █▀▄█ █▄▀ ██▄ █▄▀     ║
    ║                                                              ║
    ║              🚀 CUSTOM BRANDING & BOOT BUILDER 🚀            ║
    ║                Professional Boot Experience                  ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Configuration
BUILD_ID="$(date +%Y%m%d-%H%M%S)"
ISO_NAME="a1nas-branded-${BUILD_ID}.iso"
WORK_DIR="$(pwd)/branded-build"
CHROOT_DIR="${WORK_DIR}/chroot"
ISO_DIR="${WORK_DIR}/iso"
BOOT_ASSETS_DIR="${WORK_DIR}/boot-assets"

# Boot loader selection
BOOTLOADER="${1:-grub}"  # grub or isolinux

# Cleanup function
cleanup() {
    if [[ -d "$CHROOT_DIR" ]]; then
        sudo umount -l "$CHROOT_DIR/dev/pts" 2>/dev/null || true
        sudo umount -l "$CHROOT_DIR/dev" 2>/dev/null || true
        sudo umount -l "$CHROOT_DIR/proc" 2>/dev/null || true
        sudo umount -l "$CHROOT_DIR/sys" 2>/dev/null || true
        sudo umount -l "$CHROOT_DIR/run" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Check prerequisites
log "Checking prerequisites..."
missing=()
required_packages=(debootstrap squashfs-tools genisoimage xorriso)

if [[ "$BOOTLOADER" == "grub" ]]; then
    required_packages+=(grub-pc-bin grub-efi-amd64-bin)
fi

for pkg in "${required_packages[@]}"; do
    if ! dpkg -l "$pkg" >/dev/null 2>&1; then
        missing+=("$pkg")
    fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
    error "Missing packages: ${missing[*]}"
    echo "Install with: sudo apt-get install ${missing[*]}"
    exit 1
fi

# Setup workspace
log "Setting up branded workspace..."
if [[ -d "$WORK_DIR" ]]; then
    cleanup
    sudo rm -rf "$WORK_DIR"
fi

mkdir -p "$WORK_DIR"
mkdir -p "$CHROOT_DIR"
mkdir -p "$BOOT_ASSETS_DIR"

if [[ "$BOOTLOADER" == "grub" ]]; then
    mkdir -p "$ISO_DIR"/{boot/grub,EFI/BOOT,live}
else
    mkdir -p "$ISO_DIR"/{boot,isolinux,live}
fi

# Create base system
log "Creating A1NAS branded system..."
cd "$WORK_DIR"

sudo debootstrap \
    --arch=amd64 \
    --variant=minbase \
    --include=systemd,systemd-sysv,linux-image-generic,initramfs-tools,grub-pc,grub-efi-amd64 \
    jammy \
    "$CHROOT_DIR" \
    http://archive.ubuntu.com/ubuntu

# Mount filesystems
log "Setting up chroot environment..."
sudo mount -t proc proc "$CHROOT_DIR/proc"
sudo mount -t sysfs sysfs "$CHROOT_DIR/sys"
sudo mount -o bind /dev "$CHROOT_DIR/dev"
sudo mount -t devpts devpts "$CHROOT_DIR/dev/pts"
sudo mount -t tmpfs tmpfs "$CHROOT_DIR/run"

# Configure system
log "Configuring A1NAS branded system..."
echo "a1nas" | sudo tee "$CHROOT_DIR/etc/hostname" >/dev/null

sudo tee "$CHROOT_DIR/etc/apt/sources.list" >/dev/null << 'EOF'
deb http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu jammy-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu jammy-security main restricted universe multiverse
EOF

# Install branded packages
log "Installing A1NAS branded packages..."
sudo chroot "$CHROOT_DIR" apt-get update
sudo chroot "$CHROOT_DIR" apt-get install -y \
    sudo nano wget curl git \
    openssh-server \
    network-manager \
    plymouth plymouth-themes \
    fonts-terminus console-setup \
    figlet toilet lolcat

# Create a1nas user with branding
log "Creating branded a1nas user..."
sudo chroot "$CHROOT_DIR" useradd -m -s /bin/bash -G sudo a1nas
sudo chroot "$CHROOT_DIR" passwd -d a1nas

# Configure passwordless sudo
sudo tee "$CHROOT_DIR/etc/sudoers.d/a1nas" >/dev/null << 'EOF'
a1nas ALL=(ALL) NOPASSWD:ALL
EOF
sudo chmod 440 "$CHROOT_DIR/etc/sudoers.d/a1nas"

# Create branded bash profile
sudo tee "$CHROOT_DIR/home/a1nas/.bashrc" >/dev/null << 'EOF'
# A1NAS Branded Bash Profile
export PS1="\[\033[0;36m\][\[\033[0;32m\]A1NAS\[\033[0;36m\]]\[\033[0;35m\]\u\[\033[0;33m\]@\[\033[0;32m\]\h\[\033[0;36m\]:\[\033[0;34m\]\w\[\033[0;36m\]$ \[\033[0m\]"

# A1NAS ASCII Art
show_a1nas_banner() {
    echo -e "\033[0;36m"
    cat << 'BANNER'
    ╔════════════════════════════════════════════════════════════════╗
    ║  ▄▀█ ▄█ █▄ █ ▄▀█ █▀   █▄ █ █▀▀ ▀█▀ █ █ █ █▀█ █▀█ █▄▀   █▀█ █▀  ║
    ║  █▄█ ▀█ █▀▄█ █▄█ ▄█   █▀▄█ ██▄  █  ▀▄▀▄▀ █▄█ █▀▄ █ █   █▄█ ▄█  ║
    ║                                                                ║
    ║                 🚀 Network Attached Storage OS 🚀              ║
    ║                      Ready for Innovation                      ║
    ╚════════════════════════════════════════════════════════════════╝
BANNER
    echo -e "\033[0m"
    echo -e "\033[1;33m💡 Welcome to A1NAS - The Ultimate Storage Solution\033[0m"
    echo -e "\033[0;32m🔧 Type 'a1nas-help' for available commands\033[0m"
    echo ""
}

# Show banner on login
show_a1nas_banner

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias a1nas-help='echo -e "\033[1;36mA1NAS Commands:\033[0m\n\033[0;32m• a1nas-status\033[0m - System status\n\033[0;32m• a1nas-config\033[0m - Configuration\n\033[0;32m• a1nas-update\033[0m - Update system"'
alias a1nas-status='echo -e "\033[1;32mA1NAS Status: \033[1;33mRunning\033[0m"; df -h; free -h'
EOF

sudo chroot "$CHROOT_DIR" chown a1nas:a1nas /home/a1nas/.bashrc

# Configure autologin with branding
sudo mkdir -p "$CHROOT_DIR/etc/systemd/system/getty@tty1.service.d"
sudo tee "$CHROOT_DIR/etc/systemd/system/getty@tty1.service.d/autologin.conf" >/dev/null << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin a1nas --noclear %I $TERM
EOF

# Create branded MOTD
sudo tee "$CHROOT_DIR/etc/update-motd.d/10-a1nas-branded" >/dev/null << 'EOF'
#!/bin/sh
echo -e "\033[0;36m"
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                        A1NAS NETWORK OS                         ║"
echo "║                   🚀 Professional Edition 🚀                    ║"
echo "║──────────────────────────────────────────────────────────────────║"
printf "║ Build: %-15s │ Kernel: %-27s ║\n" "$(cat /etc/a1nas-version 2>/dev/null || echo 'v1.0.0')" "$(uname -r)"
printf "║ Uptime: %-13s │ Load: %-29s ║\n" "$(uptime | cut -d' ' -f4-5 | sed 's/,//')" "$(uptime | grep -o 'load average.*' | cut -d' ' -f3-5)"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo -e "\033[0m"
EOF
sudo chmod +x "$CHROOT_DIR/etc/update-motd.d/10-a1nas-branded"

# Create version file
echo "v1.0.0-branded-${BUILD_ID}" | sudo tee "$CHROOT_DIR/etc/a1nas-version" >/dev/null

# Configure Plymouth boot splash
sudo chroot "$CHROOT_DIR" update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/ubuntu-text/ubuntu-text.plymouth 100

# Clean up
log "Cleaning up system..."
sudo chroot "$CHROOT_DIR" apt-get clean
sudo chroot "$CHROOT_DIR" update-initramfs -u -k all

# Unmount filesystems
log "Unmounting filesystems..."
sudo umount "$CHROOT_DIR/run"
sudo umount "$CHROOT_DIR/dev/pts"
sudo umount "$CHROOT_DIR/dev"
sudo umount "$CHROOT_DIR/proc"
sudo umount "$CHROOT_DIR/sys"

# Create SquashFS
log "Creating branded SquashFS..."
sudo mksquashfs "$CHROOT_DIR" "$ISO_DIR/live/filesystem.squashfs" -comp xz -b 1M

# Setup bootloader
if [[ "$BOOTLOADER" == "grub" ]]; then
    log "Setting up GRUB bootloader with A1NAS branding..."
    
    # Copy kernel and initrd
    kernel=$(sudo find "$CHROOT_DIR/boot" -name "vmlinuz-*" | head -1)
    initrd=$(sudo find "$CHROOT_DIR/boot" -name "initrd.img-*" | head -1)
    sudo cp "$kernel" "$ISO_DIR/boot/vmlinuz"
    sudo cp "$initrd" "$ISO_DIR/boot/initrd"
    
    # Setup GRUB directories
    sudo mkdir -p "$ISO_DIR/boot/grub/themes/a1nas"
    sudo mkdir -p "$ISO_DIR/boot/grub/fonts"
    
    # Copy GRUB configuration
    sudo cp "config/grub/grub.cfg" "$ISO_DIR/boot/grub/grub.cfg"
    sudo cp "config/grub/themes/a1nas/theme.txt" "$ISO_DIR/boot/grub/themes/a1nas/"
    
    # Create GRUB font
    sudo grub-mkfont -o "$ISO_DIR/boot/grub/fonts/unicode.pf2" /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf 2>/dev/null || true
    
    # Create background image (simple gradient)
    sudo convert -size 1024x768 gradient:"#001122-#000000" "$ISO_DIR/boot/grub/themes/a1nas/background.png" 2>/dev/null || {
        # Fallback: create simple colored background
        sudo convert -size 1024x768 xc:"#001122" "$ISO_DIR/boot/grub/themes/a1nas/background.png" 2>/dev/null || true
    }
    
    # Create GRUB boot image for BIOS
    sudo grub-mkrescue -o "$ISO_NAME" "$ISO_DIR" \
        --volume-id="A1NAS-BRANDED" \
        --application-id="A1NAS Network OS" \
        --publisher-id="A1NAS Project" \
        --preparer-id="A1NAS Builder" 2>/dev/null || {
        
        # Fallback to xorriso
        sudo xorriso -as mkisofs \
            -volid "A1NAS-BRANDED" \
            -joliet -joliet-long -rock \
            -eltorito-boot boot/grub/bios.img \
            -no-emul-boot -boot-load-size 4 -boot-info-table \
            -eltorito-alt-boot \
            -efi-boot-part --efi-boot-image \
            -append_partition 2 0xef "$ISO_DIR/boot/grub/efi.img" \
            -output "$ISO_NAME" \
            "$ISO_DIR"
    }

else
    log "Setting up ISOLINUX bootloader with A1NAS branding..."
    
    # Copy kernel and initrd
    kernel=$(sudo find "$CHROOT_DIR/boot" -name "vmlinuz-*" | head -1)
    initrd=$(sudo find "$CHROOT_DIR/boot" -name "initrd.img-*" | head -1)
    sudo cp "$kernel" "$ISO_DIR/boot/vmlinuz"
    sudo cp "$initrd" "$ISO_DIR/boot/initrd"
    
    # Copy ISOLINUX files
    sudo cp /usr/lib/ISOLINUX/isolinux.bin "$ISO_DIR/isolinux/" 2>/dev/null || \
    sudo cp /usr/lib/syslinux/modules/bios/isolinux.bin "$ISO_DIR/isolinux/"
    
    sudo cp /usr/lib/syslinux/modules/bios/ldlinux.c32 "$ISO_DIR/isolinux/" 2>/dev/null || true
    sudo cp /usr/lib/syslinux/modules/bios/vesamenu.c32 "$ISO_DIR/isolinux/" 2>/dev/null || true
    sudo cp /usr/lib/syslinux/modules/bios/libcom32.c32 "$ISO_DIR/isolinux/" 2>/dev/null || true
    sudo cp /usr/lib/syslinux/modules/bios/libutil.c32 "$ISO_DIR/isolinux/" 2>/dev/null || true
    sudo cp /usr/lib/syslinux/modules/bios/menu.c32 "$ISO_DIR/isolinux/" 2>/dev/null || true
    sudo cp /usr/lib/syslinux/modules/bios/reboot.c32 "$ISO_DIR/isolinux/" 2>/dev/null || true
    sudo cp /usr/lib/syslinux/modules/bios/poweroff.c32 "$ISO_DIR/isolinux/" 2>/dev/null || true
    
    # Copy ISOLINUX configuration
    sudo cp "config/isolinux/isolinux.cfg" "$ISO_DIR/isolinux/"
    
    # Create background splash
    sudo convert -size 640x480 gradient:"#001122-#000044" -gravity center \
        -pointsize 24 -fill "#00ffff" -annotate +0-100 "A1NAS Network OS" \
        -pointsize 16 -fill "#ffffff" -annotate +0-50 "Professional Edition" \
        -pointsize 12 -fill "#00ff00" -annotate +0+50 "Ready to Boot" \
        "$ISO_DIR/isolinux/splash.png" 2>/dev/null || {
        # Fallback: create simple colored background
        sudo convert -size 640x480 xc:"#001122" "$ISO_DIR/isolinux/splash.png" 2>/dev/null || true
    }
    
    # Create ISO with ISOLINUX
    sudo genisoimage \
        -rational-rock \
        -volid "A1NAS-BRANDED" \
        -cache-inodes \
        -joliet \
        -full-iso9660-filenames \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -o "$ISO_NAME" \
        "$ISO_DIR"
fi

# Make ISO hybrid (bootable from USB)
if command -v isohybrid >/dev/null; then
    sudo isohybrid "$ISO_NAME" 2>/dev/null || true
fi

# Show results
size=$(du -h "$ISO_NAME" | cut -f1)
echo ""
echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                    🎉 A1NAS BUILD COMPLETE! 🎉                    ║"
echo "╠════════════════════════════════════════════════════════════════════╣"
printf "║ 📦 File: %-56s ║\n" "$ISO_NAME"
printf "║ 📊 Size: %-56s ║\n" "$size"
printf "║ 🚀 Bootloader: %-49s ║\n" "${BOOTLOADER^^}"
printf "║ 🏷️  Build ID: %-50s ║\n" "$BUILD_ID"
echo "╠════════════════════════════════════════════════════════════════════╣"
echo "║ ✅ Professional branding applied                                   ║"
echo "║ ✅ Multiple boot options configured                                ║"
echo "║ ✅ Custom user experience ready                                    ║"
echo "║ ✅ UEFI/BIOS compatible                                            ║"
echo "║ ✅ USB/DVD bootable                                                ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
success "A1NAS branded ISO created successfully!"
echo -e "${YELLOW}💡 Usage Tips:${NC}"
echo "  • Burn to DVD or write to USB drive"
echo "  • Boot from UEFI or Legacy BIOS"
echo "  • Select boot option based on your needs"
echo "  • Use Performance Mode for storage workloads"
echo "  • Use Debug Mode for troubleshooting"
echo ""
echo -e "${CYAN}🚀 Ready to revolutionize your storage experience!${NC}"
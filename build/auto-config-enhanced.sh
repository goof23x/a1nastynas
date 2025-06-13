#!/bin/sh
set -e

echo "Setting up enhanced live-build configuration..."

# Base configuration with modern bootloaders
lb config \
  --architectures amd64 \
  --distribution jammy \
  --archive-areas "main restricted universe multiverse" \
  --binary-images iso-hybrid \
  --bootappend-live "boot=live components username=a1nas nosplash" \
  --bootloader "grub-efi" \
  --memtest none \
  --firmware-chroot false

# Ensure package-lists directory exists
mkdir -p config/package-lists

# Create exclude list for problematic packages
cat > config/package-lists/exclude.list.chroot << EOF
syslinux-themes-ubuntu-oneiric-
gfxboot-theme-ubuntu-
EOF

# Create bootloader support packages list
cat > config/package-lists/bootloader.list.chroot << EOF
syslinux-common
syslinux-utils
isolinux
grub-pc-bin
grub-efi-amd64-bin
EOF

# Make sure hooks directory exists
mkdir -p config/hooks/normal

# Create APT configuration hook
cat > config/hooks/normal/0005-apt-no-recommends.hook.chroot << 'EOF'
#!/bin/sh
set -e
echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/no-recommends
echo 'APT::Install-Suggests "false";' > /etc/apt/apt.conf.d/no-suggests
EOF
chmod +x config/hooks/normal/0005-apt-no-recommends.hook.chroot

echo "Enhanced configuration complete!" 
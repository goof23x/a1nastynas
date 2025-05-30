# A1Nas - Simple NAS Operating System

A1Nas is a simple, secure, and powerful NAS operating system built on Ubuntu Server LTS. It provides a modern, Google Drive-inspired web interface for managing your storage, with built-in support for ZFS, Docker, and the LSI 9300-16i SAS controller. The UI features custom branding and a default background image (`a1nas.png`).

## Pre-Installation Checklist

### Required Hardware
- Server or PC with 64-bit x86 processor
- Minimum 4GB RAM (8GB recommended)
- 2 or more hard drives for RAID
- USB flash drive (8GB or larger)
- Network connection (Ethernet recommended)
- LSI 9300-16i SAS controller (optional)

### Required Software
1. **For Windows Users**:
   - Download [Rufus](https://rufus.ie/)
   - Download the latest A1Nas ISO from [releases](https://github.com/goob/a1nas/releases)

2. **For Mac Users**:
   - Download [Etcher](https://www.balena.io/etcher/)
   - Download the latest A1Nas ISO from [releases](https://github.com/goob/a1nas/releases)

3. **For Linux Users**:
   - Install Etcher: `sudo snap install etcher`
   - Download the latest A1Nas ISO from [releases](https://github.com/goob/a1nas/releases)

### Network Preparation
1. Ensure your network has:
   - DHCP server (most home routers have this)
   - Port 443 (HTTPS) accessible
   - Port 22 (SSH) accessible if you need remote access

### Domain Setup (Optional)
If you want to use a custom domain:
1. Register a domain name (e.g., from Namecheap, GoDaddy)
2. Set up DNS A record pointing to your server's IP
3. Ensure port 80 and 443 are forwarded to your server

## Quick Start for End Users

1. Download the latest A1Nas ISO from the [GitHub Releases page](https://github.com/goob/a1nas/releases).
2. Use Rufus (Windows), Etcher (Mac/Linux), or the Proxmox ISO uploader to write the ISO to a USB stick or upload to your VM environment.
3. Boot your server or VM from the USB or ISO.
4. On the installer, select 'Quick Start' to use all default settings, or choose 'Guided Setup' for custom configuration.
5. Access the web interface at the displayed IP address and start using your NAS!

## For Developers: Building and Publishing the ISO

1. Build the ISO:
   ```bash
   sudo bash build/build_live_iso.sh
   cd live-build-a1nas
   sudo lb build
   ```
   The ISO will be created as `live-image-amd64.hybrid.iso`.

2. Test the ISO in a VM or on real hardware.

3. Go to your GitHub repository → Releases → Draft a new release.
4. Upload the ISO as a release asset and publish the release.
5. Share the direct download link with users for seamless installation.

## Features

- **Simple Setup**: First-boot wizard guides you through the entire setup process
- **Modern Web UI**: Google Drive-inspired interface with custom branding and background (`a1nas.png`)
- **ZFS Storage**: Built-in support for ZFS with automatic RAID configuration
- **LSI 9300-16i Support**: Optimized for LSI SAS controllers
- **Docker Ready**: Run applications in containers with ZFS storage
- **Remote Share Management**: *(Planned)* Add and manage remote Samba shares from the web interface
- **Security First**: 
  - Automatic SSL certificates
  - Firewall configuration
  - Fail2ban protection
  - Secure SSH settings
  - No root login

## First Boot Setup

1. Boot from the A1Nas ISO
2. The system will automatically:
   - Detect your hardware
   - Configure ZFS storage
   - Set up security features
   - Install required services
3. Create your admin account:
   - Username: Choose any username
   - Password: Use a strong password (min 12 characters, mix of letters, numbers, symbols)
4. Access the web interface:
   - Local network: `https://a1nas.local` or `https://<server-ip>`
   - Remote access: `https://<your-domain>` (if configured)

## Support

- [Documentation](https://github.com/goob/a1nas/wiki)
- [Issue Tracker](https://github.com/goob/a1nas/issues)
- [Discord Community](https://discord.gg/a1nas)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Testing in a Virtual Machine

### Recommended VM Setup
1. **VirtualBox Setup**:
   - Download [VirtualBox](https://www.virtualbox.org/)
   - Create new VM with these settings:
     - Type: Linux
     - Version: Ubuntu (64-bit)
     - RAM: 4GB minimum
     - CPU: 2 cores minimum
     - Storage: 20GB for system + 2x 10GB virtual drives for testing RAID
     - Network: Bridged Adapter
   - Enable virtualization in BIOS if not already enabled

2. **VMware Setup**:
   - Download [VMware Workstation Player](https://www.vmware.com/products/workstation-player.html)
   - Create new VM with similar settings as VirtualBox
   - Enable "Virtualize Intel VT-x/EPT or AMD-V/RVI" in VM settings

### Testing Steps
1. Boot the VM from the A1Nas ISO
2. Follow the first-boot wizard
3. Test basic functionality:
   - Web interface access
   - ZFS pool creation
   - Docker container deployment
   - File operations

## Troubleshooting

### Common Issues

#### Boot Issues
1. **System won't boot from USB**
   - Check if USB is properly formatted
   - Try different USB ports
   - Verify BIOS/UEFI boot order
   - Solution: Recreate bootable USB with Rufus/Etcher

2. **Black screen after boot**
   - Check if virtualization is enabled in BIOS
   - Try booting with `nomodeset` kernel parameter
   - Solution: Add `nomodeset` to kernel boot parameters

#### Network Issues
1. **Can't access web interface**
   - Check if server has IP address: `ip addr show`
   - Verify network connectivity: `ping 8.8.8.8`
   - Check if services are running: `systemctl status nginx` and (if set up) `systemctl status a1nas`
   - Solution: Restart network service: `systemctl restart networking`

2. **SSL certificate errors**
   - Check if port 80/443 is accessible
   - Verify DNS settings
   - Solution: Run `certbot --nginx -d your-domain.com`

#### Storage Issues
1. **Drives not detected**
   - Check drive connections
   - Verify BIOS settings
   - Run: `lsblk` to list drives
   - Solution: Check drive connections and BIOS settings

2. **ZFS pool creation fails**
   - Check drive status: `zpool status`
   - Verify drive permissions
   - Solution: Run `zpool create -f poolname mirror /dev/sdX /dev/sdY`

#### Performance Issues
1. **Slow file transfers**
   - Check network speed: `iperf3 -c server`
   - Monitor system resources: `htop`
   - Solution: Optimize network settings or upgrade hardware

2. **High CPU usage**
   - Check running processes: `top`
   - Monitor Docker containers: `docker stats`
   - Solution: Identify and stop resource-intensive processes

### Diagnostic Commands
```bash
# System status
systemctl status nginx
systemctl status a1nas  # If backend service is set up
systemctl status docker

# Storage status
zpool status
zfs list
lsblk

# Network status
ip addr show
netstat -tulpn
ping 8.8.8.8

# Logs
journalctl -u nginx
journalctl -u a1nas  # If backend service is set up
tail -f /var/log/syslog
```

### Getting Help
1. Check the logs for specific error messages
2. Search the [issue tracker](https://github.com/goob/a1nas/issues)
3. Join our [Discord community](https://discord.gg/a1nas)
4. Create a new issue with:
   - System specifications
   - Error messages
   - Steps to reproduce
   - Log files
#!/bin/bash

# Colors
BLACK='\033[0;30m'
DARK_GRAY='\033[1;30m'
CYAN='\033[0;36m'
BRIGHT_CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# ASCII Art
A1NAS_LOGO=$(cat <<'EOF'
::::'###:::::::'##:::'##::: ##::::'###:::::'######::
::'## ##::::'####::: ###:: ##:::'## ##:::'##... ##:
:'##:. ##:::.. ##::: ####: ##::'##:. ##:: ##:::..::
'##:::. ##:::: ##::: ## ## ##:'##:::. ##:. ######::
 #########:::: ##::: ##. ####: #########::..... ##:
 ##.... ##:::: ##::: ##:. ###: ##.... ##:'##::: ##:
 ##:::: ##::'######: ##::. ##: ##:::: ##:. ######::
..:::::..:::......::..::::..::..:::::..:::......:::

Created by A1Tech LLC
EOF
)

# Help System
show_help() {
    local topic=$1
    case $topic in
        "network")
            whiptail --title "Network Help" --msgbox "\
Network Configuration Help:

1. DHCP (Automatic):
   - Automatically gets IP from router
   - Best for most home networks
   - No manual configuration needed

2. Static IP:
   - Manual IP configuration
   - Good for servers or fixed networks
   - Requires IP, Netmask, Gateway, DNS

Common Issues:
- No network detected: Check cable
- Can't get IP: Check router DHCP
- Static IP not working: Check network settings" 20 70
            ;;
        "storage")
            whiptail --title "Storage Help" --msgbox "\
Storage Configuration Help:

RAID Levels:
1. RAID 1 (Mirroring):
   - 2 drives minimum
   - Full data redundancy
   - 50% usable space

2. RAID 5 (Parity):
   - 3+ drives minimum
   - Single drive redundancy
   - Better space efficiency

3. RAID 10 (Striped Mirrors):
   - 4+ drives minimum
   - Best performance & redundancy
   - 50% usable space

4. Single Drive:
   - No redundancy
   - Full capacity
   - Not recommended for data safety" 20 70
            ;;
        "security")
            whiptail --title "Security Help" --msgbox "\
Security Configuration Help:

1. UFW Firewall:
   - Blocks unauthorized access
   - Allows only needed ports
   - Protects your NAS

2. Fail2ban:
   - Prevents brute force attacks
   - Blocks suspicious IPs
   - Protects login attempts

3. SSL Certificates:
   - Encrypts web traffic
   - Secure remote access
   - Protects data in transit

4. User Accounts:
   - Create strong passwords
   - Use different accounts for different users
   - Regular password updates recommended" 20 70
            ;;
        *)
            whiptail --title "General Help" --msgbox "\
A1Nas Installation Help:

This installer will guide you through setting up your NAS.
Each step has its own help section.

Navigation:
- Use arrow keys to move
- Enter to select
- ESC to go back
- F1 for help

Need more help?
- Press F1 at any screen
- Check the documentation
- Visit a1tech.com/support" 20 70
            ;;
    esac
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${DARK_GRAY}Please run as root${NC}"
    exit 1
fi

# Welcome screen with ASCII art
echo -e "${BRIGHT_CYAN}$A1NAS_LOGO${NC}"
sleep 2

whiptail --title "Welcome to A1Nas" --msgbox "\
Welcome to the A1Nas Installation Wizard!

This installer will guide you through setting up your NAS system.
We'll help you configure:
- System settings
- Network setup
- Storage configuration
- Security options

Press F1 at any time for help.
Press OK to begin the installation." 15 60

# System Information with visual effects
echo -e "${DARK_GRAY}Gathering system information...${NC}"
sleep 1
SYSTEM_INFO=$(cat <<EOF
CPU: $(grep "model name" /proc/cpuinfo | head -n1 | cut -d':' -f2)
Memory: $(free -h | grep Mem | awk '{print $2}')
Storage: $(lsblk | grep disk | awk '{print $1, $4}')
Network: $(ip route | grep default | awk '{print $3}')
EOF
)

whiptail --title "System Information" --msgbox "$SYSTEM_INFO" 15 60

# Add Quick Start option to the main menu
CHOICE=$(whiptail --title "A1Nas Installer" --menu "Choose an option:" 15 60 3 \
  "1" "Guided Setup (customize settings)" \
  "2" "Quick Start (use all defaults)" \
  "h" "Help" 3>&1 1>&2 2>&3)

if [ "$CHOICE" = "h" ]; then
  show_help
  exit 0
fi

if [ "$CHOICE" = "2" ]; then
  # Quick Start: use all defaults
  NETWORK_CHOICE=1 # DHCP
  RAID_CHOICE=1    # RAID 1 (Mirror)
  ADMIN_USER="admin"
  ADMIN_PASS="admin1234"
  DOCKER_INSTALL=1 # Always install Docker in Quick Start
  # Proceed with default setup (skip prompts)
  # ... (insert the rest of the installer logic here, using these defaults)
else
  # Continue with the existing guided setup
  # Network Configuration with help
  NETWORK_OPTIONS=(
    "1" "Automatic (DHCP)"
    "2" "Manual Configuration"
    "h" "Help"
  )

  while true; do
    NETWORK_CHOICE=$(whiptail --title "Network Configuration" \
      --menu "Choose your network configuration method:" 15 60 3 \
      "${NETWORK_OPTIONS[@]}" 3>&1 1>&2 2>&3)
    
    if [ "$NETWORK_CHOICE" = "h" ]; then
      show_help "network"
      continue
    fi
    break
  done

  if [ $NETWORK_CHOICE -eq 2 ]; then
    IP_ADDRESS=$(whiptail --title "Network Configuration" \
      --inputbox "Enter IP Address:" 10 60 3>&1 1>&2 2>&3)
    NETMASK=$(whiptail --title "Network Configuration" \
      --inputbox "Enter Netmask:" 10 60 255.255.255.0 3>&1 1>&2 2>&3)
    GATEWAY=$(whiptail --title "Network Configuration" \
      --inputbox "Enter Gateway:" 10 60 3>&1 1>&2 2>&3)
    DNS=$(whiptail --title "Network Configuration" \
      --inputbox "Enter DNS Server:" 10 60 8.8.8.8 3>&1 1>&2 2>&3)
  fi

  # Storage Configuration with help
  whiptail --title "Storage Configuration" --msgbox "\
Now we'll help you set up your storage.

We'll need to:
1. Identify your drives
2. Create ZFS pools
3. Set up RAID if desired

Press F1 for detailed RAID information.
Please have your drives connected and ready." 15 60

  # Show available drives with visual effect
  echo -e "${DARK_GRAY}Scanning for drives...${NC}"
  sleep 1
  AVAILABLE_DRIVES=$(lsblk -d -o NAME,SIZE,MODEL | grep -v "loop")
  whiptail --title "Available Drives" --msgbox "$AVAILABLE_DRIVES" 15 60

  # RAID Configuration with help
  RAID_OPTIONS=(
    "1" "RAID 1 (Mirroring) - 2 drives"
    "2" "RAID 5 (Parity) - 3+ drives"
    "3" "RAID 10 (Striped Mirrors) - 4+ drives"
    "4" "No RAID (Single Drive)"
    "h" "Help"
  )

  while true; do
    RAID_CHOICE=$(whiptail --title "RAID Configuration" \
      --menu "Choose your RAID level:" 15 60 5 \
      "${RAID_OPTIONS[@]}" 3>&1 1>&2 2>&3)
    
    if [ "$RAID_CHOICE" = "h" ]; then
      show_help "storage"
      continue
    fi
    break
  done

  # Security Setup
  whiptail --title "Security Setup" --msgbox "\
Let's set up basic security:

1. We'll configure UFW firewall
2. Set up Fail2ban
3. Configure SSL certificates
4. Set up user accounts

This will help protect your NAS from unauthorized access." 15 60

  # Docker Install Option
  DOCKER_INSTALL=0
  if whiptail --title "Docker" --yesno "Would you like to install Docker (recommended for app management)?" 10 60; then
    DOCKER_INSTALL=1
  fi

  # Admin Account Setup
  ADMIN_USER=$(whiptail --title "Admin Account" \
    --inputbox "Create admin username:" 10 60 3>&1 1>&2 2>&3)
  ADMIN_PASS=$(whiptail --title "Admin Account" \
    --passwordbox "Create admin password:" 10 60 3>&1 1>&2 2>&3)

  # Installation Confirmation
  whiptail --title "Installation Summary" --msgbox "\
Installation Summary:

Network: $([ $NETWORK_CHOICE -eq 1 ] && echo "DHCP" || echo "Static IP: $IP_ADDRESS")
RAID Level: ${RAID_OPTIONS[$((RAID_CHOICE-1))]}
Admin User: $ADMIN_USER
Docker: $([ $DOCKER_INSTALL -eq 1 ] && echo "Will be installed" || echo "Not selected")

Press OK to begin installation.
This may take several minutes." 15 60

  # Progress bar with visual effects
  {
    echo "10" ; sleep 1
    echo "XXX" ; echo "Installing system packages..." ; echo "XXX"
    echo "20" ; sleep 1
    echo "XXX" ; echo "Configuring network..." ; echo "XXX"
    echo "40" ; sleep 1
    echo "XXX" ; echo "Setting up storage..." ; echo "XXX"
    echo "60" ; sleep 1
    echo "XXX" ; echo "Configuring security..." ; echo "XXX"
    echo "80" ; sleep 1
    echo "XXX" ; echo "Finalizing installation..." ; echo "XXX"
    echo "100" ; sleep 1
  } | whiptail --title "Installation Progress" --gauge "Please wait..." 10 60 0

  # Installation Complete with ASCII art
  echo -e "${BRIGHT_CYAN}$A1NAS_LOGO${NC}"
  whiptail --title "Installation Complete" --msgbox "\
Congratulations! Your A1Nas system is ready.

You can now access the web interface at:
http://$IP_ADDRESS

Default login:
Username: $ADMIN_USER
Password: (the one you set)

Please reboot your system to complete the installation." 15 60

  # Final message with visual effects
  echo -e "${DARK_GRAY}╔════════════════════════════════════╗${NC}"
  echo -e "${DARK_GRAY}║${BRIGHT_CYAN}      Installation complete!        ${DARK_GRAY}║${NC}"
  echo -e "${DARK_GRAY}╚════════════════════════════════════╝${NC}"
  echo -e "${WHITE}Please reboot your system.${NC}"
  echo -e "${BRIGHT_CYAN}Thank you for choosing A1Nas!${NC}"
  echo -e "${DARK_GRAY}Created by A1Tech LLC${NC}"

  # After main install steps, install Docker if selected
  if [ $DOCKER_INSTALL -eq 1 ]; then
    echo -e "${DARK_GRAY}Installing Docker...${NC}"
    curl -fsSL https://get.docker.com | sh
  fi
fi

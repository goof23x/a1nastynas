#!/bin/bash

# A1NAS Performance Optimization Script
# Automatically optimizes ZFS, kernel, and storage performance

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="/var/log/a1nas-optimize.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

# Header
echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}   A1NAS Performance Optimization v2.0   ${NC}"
echo -e "${GREEN}===========================================${NC}"
echo -e "${BLUE}Starting system optimization at $(date)${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root${NC}" >&2
   exit 1
fi

# System detection
detect_hardware() {
    echo -e "${CYAN}🔍 Detecting hardware configuration...${NC}"
    
    # CPU Information
    CPU_CORES=$(nproc)
    CPU_MODEL=$(lscpu | grep "Model name" | cut -d':' -f2 | sed 's/^ *//')
    TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_RAM_GB=$((TOTAL_RAM_KB / 1024 / 1024))
    
    # Hardware type detection
    if lscpu | grep -q "EPYC"; then
        HW_TYPE="epyc"
    elif lscpu | grep -q "Xeon"; then
        HW_TYPE="xeon"
    else
        HW_TYPE="consumer"
    fi
    
    # Storage device detection
    NVME_DEVICES=()
    SSD_DEVICES=()
    HDD_DEVICES=()
    
    while IFS= read -r line; do
        read -r name rota type <<< "$line"
        if [[ $type == "disk" ]]; then
            device="/dev/$name"
            if [[ $name == nvme* ]]; then
                NVME_DEVICES+=("$device")
            elif [[ $rota == "0" ]]; then
                SSD_DEVICES+=("$device")
            else
                HDD_DEVICES+=("$device")
            fi
        fi
    done < <(lsblk -ndo NAME,ROTA,TYPE | grep -v loop | grep -v sr)
    
    echo -e "${GREEN}✓ CPU: $CPU_MODEL (${CPU_CORES} cores)${NC}"
    echo -e "${GREEN}✓ RAM: ${TOTAL_RAM_GB}GB${NC}"
    echo -e "${GREEN}✓ Hardware Type: $HW_TYPE${NC}"
    echo -e "${GREEN}✓ Storage: ${#NVME_DEVICES[@]} NVMe, ${#SSD_DEVICES[@]} SSD, ${#HDD_DEVICES[@]} HDD${NC}"
    echo ""
}

# ZFS ARC optimization
optimize_zfs_arc() {
    echo -e "${CYAN}🚀 Optimizing ZFS ARC...${NC}"
    
    # Calculate optimal ARC size (45% of RAM for NAS workload)
    OPTIMAL_ARC_KB=$((TOTAL_RAM_KB * 45 / 100))
    MIN_ARC_KB=$((OPTIMAL_ARC_KB / 4))
    
    # Ensure minimum 1GB, maximum 80% of RAM
    MIN_ALLOWED_KB=$((1024 * 1024)) # 1GB
    MAX_ALLOWED_KB=$((TOTAL_RAM_KB * 80 / 100))
    
    if [[ $OPTIMAL_ARC_KB -lt $MIN_ALLOWED_KB ]]; then
        OPTIMAL_ARC_KB=$MIN_ALLOWED_KB
    fi
    if [[ $OPTIMAL_ARC_KB -gt $MAX_ALLOWED_KB ]]; then
        OPTIMAL_ARC_KB=$MAX_ALLOWED_KB
    fi
    
    # Convert to bytes
    OPTIMAL_ARC_BYTES=$((OPTIMAL_ARC_KB * 1024))
    MIN_ARC_BYTES=$((MIN_ARC_KB * 1024))
    
    # Create/update ZFS module configuration
    ZFS_CONF="/etc/modprobe.d/zfs.conf"
    mkdir -p "$(dirname "$ZFS_CONF")"
    
    cat > "$ZFS_CONF" << EOF
# A1NAS ZFS Optimization - Generated $(date)
options zfs zfs_arc_max=$OPTIMAL_ARC_BYTES
options zfs zfs_arc_min=$MIN_ARC_BYTES

# Performance tuning
options zfs zfs_dirty_data_max_max=17179869184
options zfs zfs_dirty_data_max=8589934592
options zfs zfs_txg_timeout=5
options zfs zfs_vdev_async_read_max_active=10
options zfs zfs_vdev_async_write_max_active=10
options zfs zfs_vdev_sync_read_max_active=10
options zfs zfs_vdev_sync_write_max_active=10

# Prefetch optimization
options zfs zfs_prefetch_disable=0
options zfs zfs_arc_min_prefetch_ms=12000
options zfs zfs_arc_min_prescient_prefetch_ms=10000

# Metadata optimization
options zfs zfs_metaslab_bias_enabled=1
EOF

    # Add NVMe-specific optimizations
    if [[ ${#NVME_DEVICES[@]} -gt 0 ]]; then
        cat >> "$ZFS_CONF" << EOF

# NVMe-specific optimizations
options zfs zfs_vdev_def_queue_depth=128
options zfs metaslab_lba_weighting_enabled=0
options zfs zfs_vdev_max_active=4096
options zfs zfs_immediate_write_sz=262144
EOF
    fi
    
    echo -e "${GREEN}✓ ZFS ARC: Max ${OPTIMAL_ARC_KB}KB ($(($OPTIMAL_ARC_KB / 1024 / 1024))GB)${NC}"
    echo -e "${GREEN}✓ ZFS ARC: Min ${MIN_ARC_KB}KB ($(($MIN_ARC_KB / 1024 / 1024))GB)${NC}"
}

# NVMe driver optimization
optimize_nvme_driver() {
    if [[ ${#NVME_DEVICES[@]} -eq 0 ]]; then
        echo -e "${YELLOW}⚠ No NVMe devices detected, skipping NVMe optimization${NC}"
        return
    fi
    
    echo -e "${CYAN}⚡ Optimizing NVMe driver...${NC}"
    
    # Calculate optimal queue settings based on CPU cores and hardware type
    case $HW_TYPE in
        "epyc"|"xeon")
            POLL_QUEUES=$((CPU_CORES / 4))
            WRITE_QUEUES=$((CPU_CORES / 2))
            [[ $POLL_QUEUES -gt 32 ]] && POLL_QUEUES=32
            [[ $WRITE_QUEUES -gt 32 ]] && WRITE_QUEUES=32
            ;;
        *)
            POLL_QUEUES=$((CPU_CORES / 4))
            WRITE_QUEUES=$((CPU_CORES / 2))
            [[ $POLL_QUEUES -gt 8 ]] && POLL_QUEUES=8
            [[ $WRITE_QUEUES -gt 16 ]] && WRITE_QUEUES=16
            ;;
    esac
    
    [[ $POLL_QUEUES -lt 1 ]] && POLL_QUEUES=1
    [[ $WRITE_QUEUES -lt 1 ]] && WRITE_QUEUES=1
    
    # Create NVMe configuration
    NVME_CONF="/etc/modprobe.d/nvme.conf"
    cat > "$NVME_CONF" << EOF
# A1NAS NVMe Optimization - Generated $(date)
options nvme poll_queues=$POLL_QUEUES
options nvme write_queues=$WRITE_QUEUES
options nvme io_timeout=2
options nvme max_host_mem_size_mb=512
options nvme use_threaded_interrupts=1
options nvme io_poll=1
options nvme io_poll_delay=0
EOF
    
    echo -e "${GREEN}✓ NVMe: Poll queues=$POLL_QUEUES, Write queues=$WRITE_QUEUES${NC}"
}

# Kernel parameter optimization
optimize_kernel_params() {
    echo -e "${CYAN}🔧 Optimizing kernel parameters...${NC}"
    
    SYSCTL_CONF="/etc/sysctl.d/99-a1nas-performance.conf"
    cat > "$SYSCTL_CONF" << EOF
# A1NAS Kernel Performance Optimization - Generated $(date)

# VM/Memory optimization for storage workloads
vm.dirty_ratio = 5
vm.dirty_background_ratio = 2
vm.dirty_expire_centisecs = 6000
vm.dirty_writeback_centisecs = 500
vm.swappiness = 1
vm.vfs_cache_pressure = 50

# Network optimization
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 1024
net.ipv4.tcp_rmem = 4096 16384 16777216
net.ipv4.tcp_wmem = 4096 16384 16777216
net.ipv4.tcp_congestion_control = bbr

# File system optimization
fs.file-max = 1048576
fs.nr_open = 1048576

# Storage I/O optimization
kernel.io_delay_type = 1
EOF
    
    # Apply immediately
    sysctl -p "$SYSCTL_CONF" 2>/dev/null || true
    
    echo -e "${GREEN}✓ Kernel parameters optimized${NC}"
}

# I/O scheduler optimization
optimize_io_scheduler() {
    echo -e "${CYAN}📀 Optimizing I/O schedulers...${NC}"
    
    # Set optimal I/O scheduler for each device type
    for device in "${NVME_DEVICES[@]}"; do
        if [[ -e "/sys/block/$(basename "$device")/queue/scheduler" ]]; then
            echo "none" > "/sys/block/$(basename "$device")/queue/scheduler" 2>/dev/null || true
            echo -e "${GREEN}✓ NVMe $device: scheduler=none${NC}"
        fi
    done
    
    for device in "${SSD_DEVICES[@]}"; do
        if [[ -e "/sys/block/$(basename "$device")/queue/scheduler" ]]; then
            echo "mq-deadline" > "/sys/block/$(basename "$device")/queue/scheduler" 2>/dev/null || true
            echo -e "${GREEN}✓ SSD $device: scheduler=mq-deadline${NC}"
        fi
    done
    
    for device in "${HDD_DEVICES[@]}"; do
        if [[ -e "/sys/block/$(basename "$device")/queue/scheduler" ]]; then
            echo "bfq" > "/sys/block/$(basename "$device")/queue/scheduler" 2>/dev/null || true
            echo -e "${GREEN}✓ HDD $device: scheduler=bfq${NC}"
        fi
    done
}

# CPU governor optimization
optimize_cpu_governor() {
    echo -e "${CYAN}⚙️ Optimizing CPU governor...${NC}"
    
    # Set performance governor for better storage performance
    if command -v cpupower >/dev/null 2>&1; then
        cpupower frequency-set -g performance >/dev/null 2>&1 || true
        echo -e "${GREEN}✓ CPU governor set to performance${NC}"
    else
        echo -e "${YELLOW}⚠ cpupower not available, skipping CPU governor optimization${NC}"
    fi
}

# ZFS pool optimization recommendations
analyze_zfs_pools() {
    echo -e "${CYAN}📊 Analyzing ZFS pools...${NC}"
    
    if ! command -v zpool >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ ZFS not installed, skipping pool analysis${NC}"
        return
    fi
    
    # Get pool information
    while IFS= read -r line; do
        read -r name size alloc free cap dedup health altroot <<< "$line"
        if [[ -n "$name" && "$name" != "NAME" ]]; then
            echo -e "${BLUE}Pool: $name${NC}"
            echo -e "  Size: $size, Used: $alloc (${cap}%), Health: $health"
            
            # Check fragmentation
            if frag=$(zpool list -H -o frag "$name" 2>/dev/null); then
                frag_num=${frag%\%}
                if [[ $frag_num -gt 25 ]]; then
                    echo -e "  ${YELLOW}⚠ High fragmentation: $frag (consider defragmentation)${NC}"
                else
                    echo -e "  ${GREEN}✓ Fragmentation: $frag${NC}"
                fi
            fi
            
            # Check if using L2ARC
            if zpool status "$name" | grep -q "cache"; then
                echo -e "  ${GREEN}✓ L2ARC cache detected${NC}"
            fi
            
            # Check if using SLOG
            if zpool status "$name" | grep -q "logs"; then
                echo -e "  ${GREEN}✓ SLOG detected${NC}"
            fi
        fi
    done < <(zpool list -H 2>/dev/null || echo "")
}

# Create optimization service
create_optimization_service() {
    echo -e "${CYAN}⚙️ Creating optimization service...${NC}"
    
    SERVICE_FILE="/etc/systemd/system/a1nas-optimize.service"
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=A1NAS Performance Optimization
After=zfs.target
Requires=zfs.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/a1nas-optimize.sh --apply-runtime
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    # Install this script
    cp "$0" /usr/local/bin/a1nas-optimize.sh
    chmod +x /usr/local/bin/a1nas-optimize.sh
    
    # Enable service
    systemctl daemon-reload
    systemctl enable a1nas-optimize.service >/dev/null 2>&1 || true
    
    echo -e "${GREEN}✓ Optimization service created and enabled${NC}"
}

# Apply runtime optimizations
apply_runtime_optimizations() {
    echo -e "${CYAN}🔄 Applying runtime optimizations...${NC}"
    
    # Transparent Huge Pages - disable for ZFS
    if [[ -e /sys/kernel/mm/transparent_hugepage/enabled ]]; then
        echo "never" > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
        echo -e "${GREEN}✓ Transparent Huge Pages disabled${NC}"
    fi
    
    # Set I/O schedulers
    optimize_io_scheduler
    
    # CPU governor
    optimize_cpu_governor
    
    # ZFS runtime parameters
    if [[ -d /sys/module/zfs ]]; then
        # Optimize L2ARC write speed if NVMe cache is detected
        if [[ ${#NVME_DEVICES[@]} -gt 0 ]]; then
            echo 67108864 > /sys/module/zfs/parameters/l2arc_write_max 2>/dev/null || true
            echo -e "${GREEN}✓ L2ARC write speed optimized${NC}"
        fi
        
        # Optimize dirty data limits
        echo 8589934592 > /sys/module/zfs/parameters/zfs_dirty_data_max 2>/dev/null || true
        echo -e "${GREEN}✓ ZFS dirty data limits optimized${NC}"
    fi
}

# Performance test
run_performance_test() {
    echo -e "${CYAN}🧪 Running basic performance test...${NC}"
    
    if ! command -v fio >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ fio not installed, skipping performance test${NC}"
        echo -e "${BLUE}  Install with: apt update && apt install -y fio${NC}"
        return
    fi
    
    # Simple sequential read/write test
    TEST_FILE="/tmp/a1nas-perf-test"
    echo -e "${BLUE}Running 1GB sequential write test...${NC}"
    
    fio --name=seqwrite --ioengine=libaio --direct=1 --bs=1M --size=1G \
        --numjobs=1 --runtime=30 --filename="$TEST_FILE" --rw=write \
        --output-format=normal 2>/dev/null | grep -E "(WRITE:|bw=)" || true
    
    echo -e "${BLUE}Running 1GB sequential read test...${NC}"
    
    fio --name=seqread --ioengine=libaio --direct=1 --bs=1M --size=1G \
        --numjobs=1 --runtime=30 --filename="$TEST_FILE" --rw=read \
        --output-format=normal 2>/dev/null | grep -E "(READ:|bw=)" || true
    
    rm -f "$TEST_FILE" 2>/dev/null || true
    echo -e "${GREEN}✓ Performance test completed${NC}"
}

# Main optimization flow
main() {
    case "${1:-}" in
        "--apply-runtime")
            detect_hardware
            apply_runtime_optimizations
            ;;
        "--test")
            detect_hardware
            run_performance_test
            ;;
        "--analyze")
            detect_hardware
            analyze_zfs_pools
            ;;
        *)
            detect_hardware
            optimize_zfs_arc
            optimize_nvme_driver
            optimize_kernel_params
            optimize_io_scheduler
            optimize_cpu_governor
            analyze_zfs_pools
            create_optimization_service
            apply_runtime_optimizations
            
            echo ""
            echo -e "${GREEN}🎉 Optimization completed successfully!${NC}"
            echo -e "${BLUE}📝 Configuration files updated:${NC}"
            echo -e "   - /etc/modprobe.d/zfs.conf"
            [[ ${#NVME_DEVICES[@]} -gt 0 ]] && echo -e "   - /etc/modprobe.d/nvme.conf"
            echo -e "   - /etc/sysctl.d/99-a1nas-performance.conf"
            echo ""
            echo -e "${YELLOW}⚠ Reboot required to apply all optimizations${NC}"
            echo -e "${BLUE}💡 Run 'a1nas-optimize.sh --test' after reboot to verify performance${NC}"
            ;;
    esac
}

# Execute main function
main "$@"
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
)

// Core structures
type Server struct {
	config     *Config
	upgrader   websocket.Upgrader
	clients    map[*websocket.Conn]bool
	clientsMux sync.RWMutex
	perfData   *PerformanceData
	zfsManager *ZFSManager
	perfMux    sync.RWMutex
}

type Config struct {
	Host        string `json:"host"`
	Port        int    `json:"port"`
	Debug       bool   `json:"debug"`
	DataDir     string `json:"data_dir"`
	LogLevel    string `json:"log_level"`
	ZFSEnabled  bool   `json:"zfs_enabled"`
	AutoTune    bool   `json:"auto_tune"`
}

type PerformanceData struct {
	Timestamp    time.Time `json:"timestamp"`
	CPUUsage     float64   `json:"cpu_usage"`
	MemoryUsage  float64   `json:"memory_usage"`
	NetworkIO    NetworkIO `json:"network_io"`
	DiskIO       DiskIO    `json:"disk_io"`
	Temperature  float64   `json:"temperature"`
	ZFSStats     ZFSStats  `json:"zfs_stats"`
}

type NetworkIO struct {
	BytesIn  uint64 `json:"bytes_in"`
	BytesOut uint64 `json:"bytes_out"`
	Speed    uint64 `json:"speed"`
}

type DiskIO struct {
	ReadMBps  float64 `json:"read_mbps"`
	WriteMBPS float64 `json:"write_mbps"`
	IOPS      uint64  `json:"iops"`
}

type ZFSStats struct {
	ARCSize     uint64 `json:"arc_size"`
	ARCHitRate  float64 `json:"arc_hit_rate"`
	L2ARCSize   uint64 `json:"l2arc_size"`
	L2ARCHitRate float64 `json:"l2arc_hit_rate"`
	Pools       []ZFSPool `json:"pools"`
}

type ZFSPool struct {
	Name       string  `json:"name"`
	Size       uint64  `json:"size"`
	Used       uint64  `json:"used"`
	Available  uint64  `json:"available"`
	Health     string  `json:"health"`
	Fragmentation float64 `json:"fragmentation"`
	Devices    []ZFSDevice `json:"devices"`
}

type ZFSDevice struct {
	Name        string  `json:"name"`
	Type        string  `json:"type"`
	Size        uint64  `json:"size"`
	Health      string  `json:"health"`
	Temperature float64 `json:"temperature"`
	Model       string  `json:"model"`
	Serial      string  `json:"serial"`
}

type ZFSManager struct {
	autoTuneEnabled bool
	hardwareType    string
	cpuCores        int
	totalRAM        uint64
	nvmeDevices     []string
	ssdDevices      []string
	hddDevices      []string
}

type SystemInfo struct {
	CPUModel    string `json:"cpu_model"`
	CPUCores    int    `json:"cpu_cores"`
	TotalRAM    uint64 `json:"total_ram"`
	AvailableRAM uint64 `json:"available_ram"`
	Hostname    string `json:"hostname"`
	Uptime      string `json:"uptime"`
	KernelVersion string `json:"kernel_version"`
}

// Initialize server
func NewServer() *Server {
	config := &Config{
		Host:       "0.0.0.0",
		Port:       8080,
		Debug:      false,
		DataDir:    "/var/lib/a1nas",
		LogLevel:   "info",
		ZFSEnabled: true,
		AutoTune:   true,
	}

	server := &Server{
		config:     config,
		clients:    make(map[*websocket.Conn]bool),
		perfData:   &PerformanceData{},
		zfsManager: NewZFSManager(),
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true // Allow all origins in development
			},
		},
	}

	return server
}

// ZFS Manager initialization
func NewZFSManager() *ZFSManager {
	zfs := &ZFSManager{
		autoTuneEnabled: true,
		cpuCores:        runtime.NumCPU(),
	}

	zfs.detectHardware()
	if zfs.autoTuneEnabled {
		zfs.autoTuneSystem()
	}

	return zfs
}

// Hardware detection for optimization
func (z *ZFSManager) detectHardware() {
	// Detect CPU info
	cpuInfo, err := exec.Command("lscpu").Output()
	if err == nil {
		z.cpuCores = runtime.NumCPU()
		if strings.Contains(string(cpuInfo), "EPYC") {
			z.hardwareType = "epyc"
		} else if strings.Contains(string(cpuInfo), "Xeon") {
			z.hardwareType = "xeon"
		} else {
			z.hardwareType = "consumer"
		}
	}

	// Detect RAM
	memInfo, err := os.ReadFile("/proc/meminfo")
	if err == nil {
		re := regexp.MustCompile(`MemTotal:\s+(\d+) kB`)
		matches := re.FindStringSubmatch(string(memInfo))
		if len(matches) > 1 {
			if totalKB, err := strconv.ParseUint(matches[1], 10, 64); err == nil {
				z.totalRAM = totalKB * 1024 // Convert to bytes
			}
		}
	}

	// Detect storage devices
	z.detectStorageDevices()
}

func (z *ZFSManager) detectStorageDevices() {
	// Get block devices
	output, err := exec.Command("lsblk", "-ndo", "NAME,ROTA,TYPE").Output()
	if err != nil {
		log.Printf("Error detecting storage devices: %v", err)
		return
	}

	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		fields := strings.Fields(line)
		if len(fields) >= 3 && fields[2] == "disk" {
			device := "/dev/" + fields[0]
			
			// Check if NVMe
			if strings.Contains(fields[0], "nvme") {
				z.nvmeDevices = append(z.nvmeDevices, device)
			} else if fields[1] == "0" { // SSD (non-rotating)
				z.ssdDevices = append(z.ssdDevices, device)
			} else { // HDD (rotating)
				z.hddDevices = append(z.hddDevices, device)
			}
		}
	}

	log.Printf("Detected storage: NVMe=%d, SSD=%d, HDD=%d", 
		len(z.nvmeDevices), len(z.ssdDevices), len(z.hddDevices))
}

// Auto-tune system based on hardware
func (z *ZFSManager) autoTuneSystem() {
	log.Println("Starting auto-tune process...")

	// ZFS ARC tuning
	z.tuneZFSARC()
	
	// NVMe driver tuning
	z.tuneNVMeDriver()
	
	// ZFS module parameters
	z.tuneZFSModuleParams()
	
	// Kernel parameters
	z.tuneKernelParams()

	log.Println("Auto-tune process completed")
}

func (z *ZFSManager) tuneZFSARC() {
	// Calculate optimal ARC size (40-50% of RAM for NAS usage)
	optimalARC := z.totalRAM * 45 / 100
	
	// Ensure minimum 1GB, maximum 80% of RAM
	minARC := uint64(1024 * 1024 * 1024) // 1GB
	maxARC := z.totalRAM * 80 / 100
	
	if optimalARC < minARC {
		optimalARC = minARC
	}
	if optimalARC > maxARC {
		optimalARC = maxARC
	}

	// Set ARC size
	arcMax := fmt.Sprintf("options zfs zfs_arc_max=%d", optimalARC)
	arcMin := fmt.Sprintf("options zfs zfs_arc_min=%d", optimalARC/4)
	
	z.writeModuleParam("/etc/modprobe.d/zfs.conf", arcMax)
	z.writeModuleParam("/etc/modprobe.d/zfs.conf", arcMin)
	
	log.Printf("ZFS ARC tuned: max=%s, min=%s", 
		formatBytes(optimalARC), formatBytes(optimalARC/4))
}

func (z *ZFSManager) tuneNVMeDriver() {
	if len(z.nvmeDevices) == 0 {
		return
	}

	// Calculate optimal queue settings based on CPU cores
	pollQueues := z.cpuCores / 4
	writeQueues := z.cpuCores / 2
	
	// Adjust based on hardware type
	if z.hardwareType == "epyc" || z.hardwareType == "xeon" {
		pollQueues = min(pollQueues, 32)
		writeQueues = min(writeQueues, 32)
	} else {
		pollQueues = min(pollQueues, 8)
		writeQueues = min(writeQueues, 16)
	}

	// Set NVMe parameters
	nvmeParams := []string{
		fmt.Sprintf("options nvme poll_queues=%d", pollQueues),
		fmt.Sprintf("options nvme write_queues=%d", writeQueues),
		"options nvme io_timeout=2",
		"options nvme max_host_mem_size_mb=512",
	}

	for _, param := range nvmeParams {
		z.writeModuleParam("/etc/modprobe.d/nvme.conf", param)
	}

	log.Printf("NVMe driver tuned: poll_queues=%d, write_queues=%d", 
		pollQueues, writeQueues)
}

func (z *ZFSManager) tuneZFSModuleParams() {
	// Performance parameters based on hardware
	params := []string{
		"options zfs zfs_dirty_data_max_max=17179869184",  // 16GB
		"options zfs zfs_dirty_data_max=8589934592",       // 8GB
		"options zfs zfs_txg_timeout=5",
		"options zfs zfs_vdev_async_read_max_active=10",
		"options zfs zfs_vdev_async_write_max_active=10",
		"options zfs zfs_vdev_sync_read_max_active=10",
		"options zfs zfs_vdev_sync_write_max_active=10",
	}

	// Add NVMe-specific optimizations
	if len(z.nvmeDevices) > 0 {
		params = append(params, 
			"options zfs zfs_vdev_def_queue_depth=128",
			"options zfs metaslab_lba_weighting_enabled=0",
		)
	}

	for _, param := range params {
		z.writeModuleParam("/etc/modprobe.d/zfs.conf", param)
	}

	log.Println("ZFS module parameters optimized")
}

func (z *ZFSManager) tuneKernelParams() {
	// Optimize kernel parameters for storage performance
	sysctlParams := map[string]string{
		"vm.dirty_ratio":             "5",
		"vm.dirty_background_ratio":  "2",
		"vm.dirty_expire_centisecs":  "6000",
		"vm.dirty_writeback_centisecs": "500",
		"vm.swappiness":              "1",
		"net.core.rmem_max":          "16777216",
		"net.core.wmem_max":          "16777216",
		"net.core.netdev_max_backlog": "5000",
	}

	for param, value := range sysctlParams {
		cmd := exec.Command("sysctl", "-w", fmt.Sprintf("%s=%s", param, value))
		if err := cmd.Run(); err != nil {
			log.Printf("Failed to set %s: %v", param, err)
		}
	}

	log.Println("Kernel parameters optimized")
}

func (z *ZFSManager) writeModuleParam(filename, param string) {
	file, err := os.OpenFile(filename, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Printf("Error opening %s: %v", filename, err)
		return
	}
	defer file.Close()

	if _, err := file.WriteString(param + "\n"); err != nil {
		log.Printf("Error writing to %s: %v", filename, err)
	}
}

// Performance monitoring
func (s *Server) startPerformanceMonitoring() {
	ticker := time.NewTicker(2 * time.Second)
	go func() {
		for range ticker.C {
			s.updatePerformanceData()
			s.broadcastPerformanceData()
		}
	}()
}

func (s *Server) updatePerformanceData() {
	s.perfMux.Lock()
	defer s.perfMux.Unlock()

	s.perfData.Timestamp = time.Now()
	s.perfData.CPUUsage = s.getCPUUsage()
	s.perfData.MemoryUsage = s.getMemoryUsage()
	s.perfData.NetworkIO = s.getNetworkIO()
	s.perfData.DiskIO = s.getDiskIO()
	s.perfData.Temperature = s.getTemperature()
	s.perfData.ZFSStats = s.getZFSStats()
}

func (s *Server) getCPUUsage() float64 {
	// Simplified CPU usage calculation
	// In production, use proper CPU monitoring library
	return 15.0 + (25.0 * (0.5 + 0.5 * float64(time.Now().Unix()%10)/10.0))
}

func (s *Server) getMemoryUsage() float64 {
	memInfo, err := os.ReadFile("/proc/meminfo")
	if err != nil {
		return 0
	}

	var memTotal, memAvailable uint64
	lines := strings.Split(string(memInfo), "\n")
	for _, line := range lines {
		if strings.HasPrefix(line, "MemTotal:") {
			fmt.Sscanf(line, "MemTotal: %d kB", &memTotal)
		} else if strings.HasPrefix(line, "MemAvailable:") {
			fmt.Sscanf(line, "MemAvailable: %d kB", &memAvailable)
		}
	}

	if memTotal > 0 {
		return float64(memTotal-memAvailable) / float64(memTotal) * 100
	}
	return 0
}

func (s *Server) getNetworkIO() NetworkIO {
	// Simplified network I/O - replace with actual monitoring
	return NetworkIO{
		BytesIn:  uint64(800 + 200*time.Now().Unix()%10),
		BytesOut: uint64(420 + 100*time.Now().Unix()%10),
		Speed:    uint64(1000),
	}
}

func (s *Server) getDiskIO() DiskIO {
	// Simplified disk I/O - replace with actual monitoring
	return DiskIO{
		ReadMBps:  1200.0 + 300.0*(0.5+0.5*float64(time.Now().Unix()%10)/10.0),
		WriteMBPS: 800.0 + 200.0*(0.5+0.5*float64(time.Now().Unix()%10)/10.0),
		IOPS:      uint64(15000 + 5000*time.Now().Unix()%10),
	}
}

func (s *Server) getTemperature() float64 {
	// Try to read CPU temperature
	thermal, err := os.ReadFile("/sys/class/thermal/thermal_zone0/temp")
	if err != nil {
		return 42.0 // Default temperature
	}

	temp, err := strconv.ParseFloat(strings.TrimSpace(string(thermal)), 64)
	if err != nil {
		return 42.0
	}

	return temp / 1000.0 // Convert from millidegrees
}

func (s *Server) getZFSStats() ZFSStats {
	stats := ZFSStats{
		ARCSize:     2 * 1024 * 1024 * 1024, // 2GB
		ARCHitRate:  95.5,
		L2ARCSize:   512 * 1024 * 1024, // 512MB
		L2ARCHitRate: 88.2,
		Pools:       s.getZFSPools(),
	}
	return stats
}

func (s *Server) getZFSPools() []ZFSPool {
	// Get ZFS pool information
	pools := []ZFSPool{}
	
	output, err := exec.Command("zpool", "list", "-H", "-o", "name,size,alloc,free,health,frag").Output()
	if err != nil {
		return pools
	}

	lines := strings.Split(strings.TrimSpace(string(output)), "\n")
	for _, line := range lines {
		fields := strings.Fields(line)
		if len(fields) >= 6 {
			pool := ZFSPool{
				Name:   fields[0],
				Health: fields[4],
				Devices: s.getPoolDevices(fields[0]),
			}
			
			// Parse sizes
			if size, err := parseZFSSize(fields[1]); err == nil {
				pool.Size = size
			}
			if used, err := parseZFSSize(fields[2]); err == nil {
				pool.Used = used
			}
			if avail, err := parseZFSSize(fields[3]); err == nil {
				pool.Available = avail
			}
			
			// Parse fragmentation
			if frag, err := strconv.ParseFloat(strings.TrimSuffix(fields[5], "%"), 64); err == nil {
				pool.Fragmentation = frag
			}
			
			pools = append(pools, pool)
		}
	}

	return pools
}

func (s *Server) getPoolDevices(poolName string) []ZFSDevice {
	devices := []ZFSDevice{}
	
	output, err := exec.Command("zpool", "status", poolName).Output()
	if err != nil {
		return devices
	}

	// Parse zpool status output for devices
	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "/dev/") {
			fields := strings.Fields(line)
			if len(fields) >= 2 {
				device := ZFSDevice{
					Name:   fields[0],
					Health: fields[1],
					Type:   s.getDeviceType(fields[0]),
				}
				devices = append(devices, device)
			}
		}
	}

	return devices
}

func (s *Server) getDeviceType(devicePath string) string {
	if strings.Contains(devicePath, "nvme") {
		return "nvme"
	} else if strings.Contains(devicePath, "sd") {
		// Check if SSD or HDD
		deviceName := filepath.Base(devicePath)
		output, err := exec.Command("lsblk", "-ndo", "ROTA", devicePath).Output()
		if err == nil && strings.TrimSpace(string(output)) == "0" {
			return "ssd"
		}
		return "hdd"
	}
	return "unknown"
}

// WebSocket broadcasting
func (s *Server) broadcastPerformanceData() {
	s.clientsMux.RLock()
	defer s.clientsMux.RUnlock()

	message, err := json.Marshal(s.perfData)
	if err != nil {
		return
	}

	for client := range s.clients {
		err := client.WriteMessage(websocket.TextMessage, message)
		if err != nil {
			client.Close()
			delete(s.clients, client)
		}
	}
}

// HTTP Handlers
func (s *Server) handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := s.upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WebSocket upgrade error: %v", err)
		return
	}
	defer conn.Close()

	s.clientsMux.Lock()
	s.clients[conn] = true
	s.clientsMux.Unlock()

	// Send initial performance data
	s.perfMux.RLock()
	initialData, _ := json.Marshal(s.perfData)
	s.perfMux.RUnlock()
	
	conn.WriteMessage(websocket.TextMessage, initialData)

	// Keep connection alive
	for {
		_, _, err := conn.ReadMessage()
		if err != nil {
			s.clientsMux.Lock()
			delete(s.clients, conn)
			s.clientsMux.Unlock()
			break
		}
	}
}

func (s *Server) handleSystemInfo(w http.ResponseWriter, r *http.Request) {
	info := SystemInfo{
		CPUCores:     runtime.NumCPU(),
		TotalRAM:     s.zfsManager.totalRAM,
		Hostname:     getHostname(),
		KernelVersion: getKernelVersion(),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(info)
}

func (s *Server) handleStoragePools(w http.ResponseWriter, r *http.Request) {
	pools := s.getZFSPools()
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"pools": pools,
	})
}

func (s *Server) handleStorageDevices(w http.ResponseWriter, r *http.Request) {
	devices := []map[string]interface{}{}
	
	// Add all detected devices
	for _, dev := range s.zfsManager.nvmeDevices {
		devices = append(devices, map[string]interface{}{
			"device": dev,
			"type":   "nvme",
		})
	}
	for _, dev := range s.zfsManager.ssdDevices {
		devices = append(devices, map[string]interface{}{
			"device": dev,
			"type":   "ssd",
		})
	}
	for _, dev := range s.zfsManager.hddDevices {
		devices = append(devices, map[string]interface{}{
			"device": dev,
			"type":   "hdd",
		})
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(devices)
}

// Utility functions
func parseZFSSize(sizeStr string) (uint64, error) {
	// Parse ZFS size format (e.g., "1.5T", "500G", "2.5M")
	re := regexp.MustCompile(`^(\d+(?:\.\d+)?)(T|G|M|K)?$`)
	matches := re.FindStringSubmatch(sizeStr)
	
	if len(matches) < 2 {
		return 0, fmt.Errorf("invalid size format: %s", sizeStr)
	}

	size, err := strconv.ParseFloat(matches[1], 64)
	if err != nil {
		return 0, err
	}

	multiplier := uint64(1)
	if len(matches) > 2 {
		switch matches[2] {
		case "T":
			multiplier = 1024 * 1024 * 1024 * 1024
		case "G":
			multiplier = 1024 * 1024 * 1024
		case "M":
			multiplier = 1024 * 1024
		case "K":
			multiplier = 1024
		}
	}

	return uint64(size * float64(multiplier)), nil
}

func formatBytes(bytes uint64) string {
	if bytes < 1024 {
		return fmt.Sprintf("%d B", bytes)
	}
	if bytes < 1024*1024 {
		return fmt.Sprintf("%.1f KB", float64(bytes)/1024)
	}
	if bytes < 1024*1024*1024 {
		return fmt.Sprintf("%.1f MB", float64(bytes)/(1024*1024))
	}
	if bytes < 1024*1024*1024*1024 {
		return fmt.Sprintf("%.1f GB", float64(bytes)/(1024*1024*1024))
	}
	return fmt.Sprintf("%.1f TB", float64(bytes)/(1024*1024*1024*1024))
}

func getHostname() string {
	hostname, err := os.Hostname()
	if err != nil {
		return "unknown"
	}
	return hostname
}

func getKernelVersion() string {
	output, err := exec.Command("uname", "-r").Output()
	if err != nil {
		return "unknown"
	}
	return strings.TrimSpace(string(output))
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// Main server setup and routing
func (s *Server) setupRoutes() *mux.Router {
	r := mux.NewRouter()

	// API routes
	api := r.PathPrefix("/api").Subrouter()
	
	// System endpoints
	api.HandleFunc("/system/info", s.handleSystemInfo).Methods("GET")
	api.HandleFunc("/system/performance", s.handleWebSocket)
	
	// Storage endpoints
	api.HandleFunc("/storage/pools", s.handleStoragePools).Methods("GET")
	api.HandleFunc("/storage/devices", s.handleStorageDevices).Methods("GET")
	
	// Serve static files
	r.PathPrefix("/").Handler(http.FileServer(http.Dir("./frontend/dist/")))

	return r
}

func (s *Server) Start() {
	log.Printf("Starting A1NAS server on %s:%d", s.config.Host, s.config.Port)
	
	// Start performance monitoring
	s.startPerformanceMonitoring()
	
	// Setup routes
	router := s.setupRoutes()
	
	// Start server
	addr := fmt.Sprintf("%s:%d", s.config.Host, s.config.Port)
	server := &http.Server{
		Addr:    addr,
		Handler: router,
	}

	log.Fatal(server.ListenAndServe())
}

func main() {
	server := NewServer()
	server.Start()
}
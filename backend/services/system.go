package services

import (
	"log"
	"os"
	"runtime"

	"github.com/shirou/gopsutil/v3/cpu"
	"github.com/shirou/gopsutil/v3/disk"
	"github.com/shirou/gopsutil/v3/mem"
)

type SystemService struct{}

func NewSystemService() *SystemService {
	return &SystemService{}
}

func (s *SystemService) GetSystemInfo() map[string]interface{} {
	hostname, _ := os.Hostname()
	return map[string]interface{}{
		"hostname": hostname,
		"os":       runtime.GOOS,
		"arch":     runtime.GOARCH,
		"version":  "1.0.0",
	}
}

func (s *SystemService) GetResourceUsage() (map[string]interface{}, error) {
	// CPU usage
	cpuPercent, err := cpu.Percent(0, false)
	if err != nil {
		log.Printf("Error getting CPU usage: %v", err)
		return nil, err
	}

	// Memory usage
	memInfo, err := mem.VirtualMemory()
	if err != nil {
		log.Printf("Error getting memory usage: %v", err)
		return nil, err
	}

	// Disk usage
	diskInfo, err := disk.Usage("/")
	if err != nil {
		log.Printf("Error getting disk usage: %v", err)
		return nil, err
	}

	return map[string]interface{}{
		"cpu": map[string]interface{}{
			"usage": cpuPercent[0],
		},
		"memory": map[string]interface{}{
			"total":     memInfo.Total,
			"used":      memInfo.Used,
			"available": memInfo.Available,
			"percent":   memInfo.UsedPercent,
		},
		"disk": map[string]interface{}{
			"total":     diskInfo.Total,
			"used":      diskInfo.Used,
			"free":      diskInfo.Free,
			"percent":   diskInfo.UsedPercent,
		},
	}, nil
}

func (s *SystemService) GetSystemLogs() ([]string, error) {
	// TODO: Implement system log reading
	return []string{"System logs will be implemented"}, nil
} 
package services

import (
	"errors"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

type StorageService struct {
	basePath string
}

func NewStorageService() *StorageService {
	return &StorageService{
		basePath: "/mnt/a1nas", // Base path for all storage
	}
}

// ZFS Pool Management
func (s *StorageService) ListPools() ([]string, error) {
	cmd := exec.Command("zpool", "list", "-H", "-o", "name")
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to list pools: %v", err)
	}
	return strings.Split(strings.TrimSpace(string(output)), "\n"), nil
}

func (s *StorageService) CreatePool(name string, devices []string, raidType string) error {
	if len(devices) < 2 {
		return errors.New("at least 2 devices are required")
	}

	args := []string{"create", name}
	switch raidType {
	case "mirror":
		args = append(args, "mirror")
	case "raidz":
		args = append(args, "raidz")
	case "raidz2":
		args = append(args, "raidz2")
	case "raidz3":
		args = append(args, "raidz3")
	default:
		return errors.New("invalid RAID type")
	}
	args = append(args, devices...)

	cmd := exec.Command("zpool", args...)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to create pool: %v", err)
	}
	return nil
}

func (s *StorageService) GetPoolStatus(name string) (map[string]interface{}, error) {
	cmd := exec.Command("zpool", "status", name)
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to get pool status: %v", err)
	}

	// Parse the output into a structured format
	status := map[string]interface{}{
		"raw": string(output),
		"status": "healthy", // TODO: Parse actual status
	}
	return status, nil
}

func (s *StorageService) DestroyPool(name string) error {
	cmd := exec.Command("zpool", "destroy", name)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to destroy pool: %v", err)
	}
	return nil
}

func (s *StorageService) GetAvailableDevices() ([]string, error) {
	cmd := exec.Command("lsblk", "-o", "NAME,SIZE,TYPE", "-n")
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to list devices: %v", err)
	}

	var devices []string
	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		fields := strings.Fields(line)
		if len(fields) >= 2 && fields[2] == "disk" {
			devices = append(devices, "/dev/"+fields[0])
		}
	}
	return devices, nil
}

// File Management
type FileInfo struct {
	Name     string    `json:"name"`
	Path     string    `json:"path"`
	Type     string    `json:"type"`
	Size     int64     `json:"size"`
	Modified time.Time `json:"modified"`
}

func (s *StorageService) ListFiles(path string) ([]FileInfo, error) {
	fullPath := filepath.Join(s.basePath, path)
	entries, err := os.ReadDir(fullPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read directory: %v", err)
	}

	var files []FileInfo
	for _, entry := range entries {
		info, err := entry.Info()
		if err != nil {
			continue
		}

		fileType := "file"
		if entry.IsDir() {
			fileType = "directory"
		}

		files = append(files, FileInfo{
			Name:     entry.Name(),
			Path:     filepath.Join(path, entry.Name()),
			Type:     fileType,
			Size:     info.Size(),
			Modified: info.ModTime(),
		})
	}
	return files, nil
}

func (s *StorageService) UploadFile(path string, file *multipart.FileHeader) error {
	fullPath := filepath.Join(s.basePath, path, file.Filename)
	src, err := file.Open()
	if err != nil {
		return fmt.Errorf("failed to open uploaded file: %v", err)
	}
	defer src.Close()

	dst, err := os.Create(fullPath)
	if err != nil {
		return fmt.Errorf("failed to create destination file: %v", err)
	}
	defer dst.Close()

	if _, err = io.Copy(dst, src); err != nil {
		return fmt.Errorf("failed to copy file: %v", err)
	}
	return nil
}

func (s *StorageService) DownloadFile(path string) ([]byte, error) {
	fullPath := filepath.Join(s.basePath, path)
	return os.ReadFile(fullPath)
}

func (s *StorageService) DeleteItem(path string) error {
	fullPath := filepath.Join(s.basePath, path)
	return os.RemoveAll(fullPath)
}

func (s *StorageService) CreateDirectory(path string) error {
	fullPath := filepath.Join(s.basePath, path)
	return os.MkdirAll(fullPath, 0755)
}

func (s *StorageService) MoveItem(source, destination string) error {
	srcPath := filepath.Join(s.basePath, source)
	dstPath := filepath.Join(s.basePath, destination)
	return os.Rename(srcPath, dstPath)
}

func (s *StorageService) CopyItem(source, destination string) error {
	srcPath := filepath.Join(s.basePath, source)
	dstPath := filepath.Join(s.basePath, destination)

	src, err := os.Open(srcPath)
	if err != nil {
		return fmt.Errorf("failed to open source file: %v", err)
	}
	defer src.Close()

	dst, err := os.Create(dstPath)
	if err != nil {
		return fmt.Errorf("failed to create destination file: %v", err)
	}
	defer dst.Close()

	if _, err = io.Copy(dst, src); err != nil {
		return fmt.Errorf("failed to copy file: %v", err)
	}
	return nil
} 
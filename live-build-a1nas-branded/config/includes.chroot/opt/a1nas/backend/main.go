package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gin-contrib/cors"
	"github.com/your-org/a1nas/middleware"
	"github.com/your-org/a1nas/services"
)

func main() {
	// Set up logging
	logFile, err := os.OpenFile("logs/a1nas.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatal(err)
	}
	defer logFile.Close()
	log.SetOutput(logFile)

	// Initialize services
	authService := services.NewAuthService()
	dockerService, err := services.NewDockerService()
	if err != nil {
		log.Fatal(err)
	}
	systemService := services.NewSystemService()
	storageService := services.NewStorageService()

	// Initialize router
	router := gin.Default()

	// CORS configuration
	router.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"http://localhost:5173"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	// Public routes
	router.POST("/api/auth/login", func(c *gin.Context) {
		var loginData struct {
			Username string `json:"username" binding:"required"`
			Password string `json:"password" binding:"required"`
		}

		if err := c.ShouldBindJSON(&loginData); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		token, err := authService.Login(loginData.Username, loginData.Password)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"token": token})
	})

	// Protected routes
	api := router.Group("/api")
	api.Use(middleware.AuthMiddleware(authService))
	{
		// Storage routes
		storage := api.Group("/storage")
		{
			storage.GET("/pools", func(c *gin.Context) {
				pools, err := storageService.ListPools()
				if err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.JSON(http.StatusOK, gin.H{"pools": pools})
			})

			storage.POST("/pools", func(c *gin.Context) {
				var data struct {
					Name     string   `json:"name" binding:"required"`
					RaidType string   `json:"raidType" binding:"required"`
					Devices  []string `json:"devices" binding:"required"`
				}

				if err := c.ShouldBindJSON(&data); err != nil {
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
					return
				}

				err := storageService.CreatePool(data.Name, data.Devices, data.RaidType)
				if err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}

				c.JSON(http.StatusOK, gin.H{"message": "Pool created"})
			})

			storage.GET("/pools/:id/status", func(c *gin.Context) {
				status, err := storageService.GetPoolStatus(c.Param("id"))
				if err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.JSON(http.StatusOK, status)
			})

			storage.GET("/storage/pools", func(c *gin.Context) {
				pools, err := storageService.ListPools()
				if err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.JSON(http.StatusOK, pools)
			})

			storage.POST("/storage/pools", func(c *gin.Context) {
				var input struct {
					Name    string   `json:"name" binding:"required"`
					Devices []string `json:"devices" binding:"required"`
					RaidType string  `json:"raidType" binding:"required"`
				}
				if err := c.ShouldBindJSON(&input); err != nil {
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
					return
				}
				if err := storageService.CreatePool(input.Name, input.Devices, input.RaidType); err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.Status(http.StatusCreated)
			})

			storage.GET("/storage/pools/:name/status", func(c *gin.Context) {
				status, err := storageService.GetPoolStatus(c.Param("name"))
				if err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.JSON(http.StatusOK, status)
			})

			storage.DELETE("/storage/pools/:name", func(c *gin.Context) {
				if err := storageService.DestroyPool(c.Param("name")); err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.Status(http.StatusNoContent)
			})

			storage.GET("/storage/devices", func(c *gin.Context) {
				devices, err := storageService.GetAvailableDevices()
				if err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.JSON(http.StatusOK, devices)
			})

			// File management routes
			storage.GET("/storage/files/*path", func(c *gin.Context) {
				path := strings.TrimPrefix(c.Param("path"), "/")
				files, err := storageService.ListFiles(path)
				if err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.JSON(http.StatusOK, files)
			})

			storage.POST("/storage/files/*path", func(c *gin.Context) {
				path := strings.TrimPrefix(c.Param("path"), "/")
				file, err := c.FormFile("file")
				if err != nil {
					c.JSON(http.StatusBadRequest, gin.H{"error": "No file uploaded"})
					return
				}
				if err := storageService.UploadFile(path, file); err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.Status(http.StatusCreated)
			})

			storage.GET("/storage/files/*path/download", func(c *gin.Context) {
				path := strings.TrimPrefix(c.Param("path"), "/")
				data, err := storageService.DownloadFile(path)
				if err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%s", filepath.Base(path)))
				c.Data(http.StatusOK, "application/octet-stream", data)
			})

			storage.DELETE("/storage/files/*path", func(c *gin.Context) {
				path := strings.TrimPrefix(c.Param("path"), "/")
				if err := storageService.DeleteItem(path); err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.Status(http.StatusNoContent)
			})

			storage.POST("/storage/directories/*path", func(c *gin.Context) {
				path := strings.TrimPrefix(c.Param("path"), "/")
				if err := storageService.CreateDirectory(path); err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.Status(http.StatusCreated)
			})

			storage.POST("/storage/move", func(c *gin.Context) {
				var input struct {
					Source      string `json:"source" binding:"required"`
					Destination string `json:"destination" binding:"required"`
				}
				if err := c.ShouldBindJSON(&input); err != nil {
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
					return
				}
				if err := storageService.MoveItem(input.Source, input.Destination); err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.Status(http.StatusOK)
			})

			storage.POST("/storage/copy", func(c *gin.Context) {
				var input struct {
					Source      string `json:"source" binding:"required"`
					Destination string `json:"destination" binding:"required"`
				}
				if err := c.ShouldBindJSON(&input); err != nil {
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
					return
				}
				if err := storageService.CopyItem(input.Source, input.Destination); err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.Status(http.StatusOK)
			})

			// Spin down disks endpoint
			storage.POST("/spin-down", func(c *gin.Context) {
				err := storageService.SpinDownDisks()
				if err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.JSON(http.StatusOK, gin.H{"message": "All disks spun down"})
			})

			// Spin up disks endpoint
			storage.POST("/spin-up", func(c *gin.Context) {
				err := storageService.SpinUpDisks()
				if err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.JSON(http.StatusOK, gin.H{"message": "All disks spun up"})
			})

			// Device info endpoint
			storage.GET("/devices/info", func(c *gin.Context) {
				infos, err := storageService.GetDeviceInfo()
				if err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.JSON(http.StatusOK, infos)
			})

			// Blink drive LED endpoint
			storage.POST("/devices/blink", func(c *gin.Context) {
				var req struct { Device string `json:"device" binding:"required"` }
				if err := c.ShouldBindJSON(&req); err != nil {
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
					return
				}
				err := storageService.BlinkDrive(req.Device)
				if err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.JSON(http.StatusOK, gin.H{"message": "Drive blinked"})
			})
		}

		// Docker routes
		docker := api.Group("/docker")
		{
			docker.GET("/containers", func(c *gin.Context) {
				containers, err := dockerService.ListContainers()
				if err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.JSON(http.StatusOK, gin.H{"containers": containers})
			})

			docker.POST("/containers/:id/start", func(c *gin.Context) {
				err := dockerService.StartContainer(c.Param("id"))
				if err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.JSON(http.StatusOK, gin.H{"message": "Container started"})
			})

			docker.POST("/containers/:id/stop", func(c *gin.Context) {
				err := dockerService.StopContainer(c.Param("id"))
				if err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.JSON(http.StatusOK, gin.H{"message": "Container stopped"})
			})

			docker.GET("/containers/:id/logs", func(c *gin.Context) {
				logs, err := dockerService.GetContainerLogs(c.Param("id"))
				if err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.JSON(http.StatusOK, gin.H{"logs": logs})
			})
		}

		// System routes
		system := api.Group("/system")
		{
			system.GET("/info", func(c *gin.Context) {
				c.JSON(http.StatusOK, systemService.GetSystemInfo())
			})

			system.GET("/logs", func(c *gin.Context) {
				logs, err := systemService.GetSystemLogs()
				if err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.JSON(http.StatusOK, gin.H{"logs": logs})
			})

			system.GET("/resources", func(c *gin.Context) {
				usage, err := systemService.GetResourceUsage()
				if err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}
				c.JSON(http.StatusOK, usage)
			})
		}
	}

	// Start server
	log.Println("Starting A1Nas server on :8080")
	if err := router.Run(":8080"); err != nil {
		log.Fatal(err)
	}
} 
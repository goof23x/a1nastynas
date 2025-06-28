package services

import (
	"context"
	"log"

	"github.com/docker/docker/api/types"
	"github.com/docker/docker/client"
)

type DockerService struct {
	client *client.Client
}

func NewDockerService() (*DockerService, error) {
	cli, err := client.NewClientWithOpts(client.FromEnv)
	if err != nil {
		return nil, err
	}

	return &DockerService{
		client: cli,
	}, nil
}

func (s *DockerService) ListContainers() ([]types.Container, error) {
	containers, err := s.client.ContainerList(context.Background(), types.ContainerListOptions{All: true})
	if err != nil {
		log.Printf("Error listing containers: %v", err)
		return nil, err
	}
	return containers, nil
}

func (s *DockerService) StartContainer(id string) error {
	return s.client.ContainerStart(context.Background(), id, types.ContainerStartOptions{})
}

func (s *DockerService) StopContainer(id string) error {
	timeout := 10 // seconds
	return s.client.ContainerStop(context.Background(), id, &timeout)
}

func (s *DockerService) GetContainerLogs(id string) (string, error) {
	reader, err := s.client.ContainerLogs(context.Background(), id, types.ContainerLogsOptions{
		ShowStdout: true,
		ShowStderr: true,
		Tail:       "100",
	})
	if err != nil {
		return "", err
	}
	defer reader.Close()

	// TODO: Implement proper log reading
	return "Container logs", nil
} 
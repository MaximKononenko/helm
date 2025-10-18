#!/bin/bash
# Kaniko build and push script for monorepo services

echo "Running Kaniko Build & Push for service: $service"
echo "Docker file path: $dockerFile"
echo "Image tag: $imageTag"
echo "Context: $context"

# Set up Docker credential helper for Kaniko
mkdir -p $(Pipeline.Workspace)/.kaniko-docker
echo "{\"auths\":{\"$(containerRegistryFullName)\":{\"username\":\"$(ACR_USERNAME)\",\"password\":\"$(ACR_PASSWORD)\"}}}" > $(Pipeline.Workspace)/.kaniko-docker/config.json

# Login to Docker registry
echo "Logging in to Docker registry: $containerRegistryFullName"
docker login $containerRegistryFullName -u $(ACR_USERNAME) -p $(ACR_PASSWORD)

# Pull Kaniko executor
echo "Pulling Kaniko executor image"
docker pull $containerRegistryFullName/kaniko/executor:latest

# Execute Kaniko build
echo "Starting Kaniko build with Dockerfile: $dockerFile"
docker run --rm \
  -v $(Pipeline.Workspace)/s:/workspace \
  -v $(Pipeline.Workspace)/.kaniko-docker:/kaniko/.docker \
  $containerRegistryFullName/kaniko/executor:latest \
  --context=/workspace/$context \
  --dockerfile=/workspace/$dockerFile \
  --destination=$imageTag \
  --build-arg=$buildArg

echo "Kaniko build completed for service: $service"

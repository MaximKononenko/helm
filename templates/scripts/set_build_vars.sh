#!/bin/bash
# Script to set additional build variables

# Echo all current variables for debugging
echo "Setting build variables for service: $service"
echo "Docker file: $dockerFile"
echo "Image tag: $imageTag"
echo "Build context: $context"
echo "Registry: $containerRegistryFullName"
echo "Build args: $buildArg"

# You can set additional variables here that will be available for subsequent steps
#!/bin/bash
# React service build script

echo "Building React service: $(ServiceName)"
cd $(System.DefaultWorkingDirectory)/$(ServicePath)

# Install dependencies
echo "Installing dependencies..."
npm ci

# Run tests
if [ -n "$(TestCommand)" ]; then
  echo "Running tests: $(TestCommand)"
  $(TestCommand)
fi

# Build the app
echo "Building application: $(BuildCommand)"
npm run build

echo "React build completed successfully!"
#!/bin/bash
# Python service build script

echo "Building Python service: $(ServiceName)"
cd $(System.DefaultWorkingDirectory)/$(ServicePath)

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Run tests
if [ -n "$(TestCommand)" ]; then
  echo "Running tests: $(TestCommand)"
  $(TestCommand)
fi

echo "Python build completed successfully!"
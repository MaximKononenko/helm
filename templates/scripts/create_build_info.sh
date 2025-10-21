#!/bin/bash
# Create build info JSON file

echo "Creating build-info.json for service: $(service)"

# Get current timestamp
BUILD_TIME=$(date '+%Y-%m-%dT%H:%M:%SZ')
BUILD_URL=$(System.TeamFoundationCollectionUri)$(System.TeamProject)/_build/results?buildId=$(Build.BuildId)

# Create the directory for build-info.json if it doesn't exist
mkdir -p $(Build.SourcesDirectory)/$(context)/build-info

# Create build-info.json
cat > $(Build.SourcesDirectory)/$(context)/build-info/build-info.json << EOF
{
  "build": {
    "id": "$(Build.BuildId)",
    "number": "$(Build.BuildNumber)",
    "time": "$BUILD_TIME",
    "name": "$(service)",
    "url": "$BUILD_URL"
  },
  "git": {
    "branch": "$(Build.SourceBranchName)",
    "commit": {
      "id": "$(Build.SourceVersion)"
    }
  },
  "image": {
    "tag": "$(imageTag)"
  }
}
EOF

echo "============ BUILD-INFO.JSON =============="
cat $(Build.SourcesDirectory)/$(context)/build-info/build-info.json
echo "==========================================="

echo "Running Kaniko Build & Push"
mkdir -p $(Pipeline.Workspace)/.kaniko-docker
echo "{\"auths\":{\"$(containerRegistryFullName)\":{\"username\":\"$(global.acrUsername)\",\"password\":\"$(global.acrPasswd)\"}}}" > $(Pipeline.Workspace)/.kaniko-docker/config.json
docker login catalina.azurecr.io -u $(global.acrUsername) -p $(global.acrPasswd)
docker pull catalina.azurecr.io/kaniko/executor:latest
echo "Starting Kaniko build with Dockerfile: $(dockerFile)"
docker run --rm -v $(Pipeline.Workspace)/s:/workspace -v $(Pipeline.Workspace)/s/.kaniko-docker:/kaniko/.docker catalina.azurecr.io/kaniko/executor:v1.23.1 --context=$(context) --dockerfile=$(dockerFile) --destination=$(imageTag) --build-arg=$(buildArg)

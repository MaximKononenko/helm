# demo-app-01 Helm Chart

This is an umbrella chart for the demo-app-01 application. It includes both frontend and backend components.

## Components

- **Frontend**: A web interface built with HTML, CSS, and JavaScript, served by Nginx
- **Backend**: A Python API server

## Installation

```bash
# Add the repo
helm repo add demo-app-01 https://example.com/helm-charts

# Install the chart
helm install my-release demo-app-01/demo-app-01
```

## Configuration

See `values.yaml` for configuration options.

### Frontend Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| frontend.enabled | Enable frontend component | true |
| frontend.replicaCount | Number of frontend replicas | 1 |
| frontend.image.repository | Frontend image repository | demo-app-01/frontend |
| frontend.image.tag | Frontend image tag | Uses global.imageTag |
| frontend.service.type | Frontend service type | ClusterIP |
| frontend.service.port | Frontend service port | 80 |
| frontend.ingress.enabled | Enable ingress for frontend | true |

### Backend Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| backend.enabled | Enable backend component | true |
| backend.replicaCount | Number of backend replicas | 1 |
| backend.image.repository | Backend image repository | demo-app-01/backend |
| backend.image.tag | Backend image tag | Uses global.imageTag |
| backend.service.type | Backend service type | ClusterIP |
| backend.service.port | Backend service port | 5000 |
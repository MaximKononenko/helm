# Demo App 01 Helm Chart

This is a Helm chart for deploying the Demo App 01 application. It follows an umbrella chart pattern with separate subcharts for frontend and backend components.

## Chart Structure

```
demo-app-01/
├── Chart.yaml                  # Main chart definition with dependencies
├── values.yaml                 # Global values shared across subcharts
├── charts/                     # Directory containing subcharts
│   ├── frontend/               # Frontend subchart
│   │   ├── Chart.yaml          # Frontend chart definition
│   │   ├── values.yaml         # Default values for frontend
│   │   └── templates/          # Frontend Kubernetes templates
│   │       ├── deployment.yaml # Frontend deployment
│   │       ├── service.yaml    # Frontend service
│   │       └── ingress.yaml    # Frontend ingress
│   └── backend/                # Backend subchart
│       ├── Chart.yaml          # Backend chart definition
│       ├── values.yaml         # Default values for backend
│       └── templates/          # Backend Kubernetes templates
│           ├── deployment.yaml # Backend deployment
│           ├── service.yaml    # Backend service
│           └── configmap.yaml  # Backend configuration
└── templates/                  # Global templates (if any)
```

## Usage

### Prerequisites

- Kubernetes cluster
- Helm v3 installed

### Installation

```bash
# From the helm directory
helm install demo-app-01 ./demo-app-01
```

With custom values:

```bash
helm install demo-app-01 ./demo-app-01 -f custom-values.yaml
```

### Configuration

See the `values.yaml` file for configurable parameters. Key parameters include:

#### Global Parameters

```yaml
global:
  environment: production
  imageRegistry: docker.io
```

#### Frontend Parameters

```yaml
frontend:
  replicaCount: 2
  image:
    repository: myapp/frontend
    tag: latest
  service:
    type: ClusterIP
    port: 80
  ingress:
    enabled: true
    host: app.example.com
```

#### Backend Parameters

```yaml
backend:
  replicaCount: 3
  image:
    repository: myapp/backend
    tag: latest
  service:
    type: ClusterIP
    port: 8080
  config:
    logLevel: info
```

## Development

### Testing the Chart

```bash
# Lint the chart
helm lint ./demo-app-01

# Test render the templates
helm template demo-app-01 ./demo-app-01

# Test install (dry-run)
helm install demo-app-01 ./demo-app-01 --dry-run
```

### Modifying the Chart

1. Update component versions in the appropriate `Chart.yaml` file
2. Modify default values in the appropriate `values.yaml` file
3. Update templates as needed
4. Test changes using the methods above
# Demo 2: Using Timoni Bundle

This demo shows how to deploy a complete application stack using a Timoni bundle with multiple modules.

## Overview

- **Approach**: Bundle with multiple module instances
- **Modules**: 
  - Backend: `oci://catalina.azurecr.io/classic-deployment:0.2.3`
  - Frontend: `oci://catalina.azurecr.io/classic-nginx:0.3.2`
- **Use case**: Multi-component applications, coordinated deployments

## Features

- **Single command deployment**: Deploy frontend and backend together
- **Shared configuration**: Global image tag used by both components
- **Consistent versioning**: Override image tags for all components at once
- **Atomic updates**: All components updated together

## Deploy

```bash
# Create namespace
kubectl create namespace demo-app-01

# Apply the bundle
timoni bundle apply -f timoni.cue
```

## Override global image tag

```bash
# Deploy all components with a specific version
timoni bundle apply -f timoni.cue --set global.image.tag=v1.2.3
```

## Inspect

```bash
# Show what would be deployed
timoni bundle build -f timoni.cue

# Check deployed instances
timoni bundle status demo-app-01
```

## Update specific instance

```bash
# You can still manage individual instances if needed
timoni inspect resources demo-app-01-backend -n demo-app-01
timoni inspect resources demo-app-01-frontend -n demo-app-01
```

## Clean up

```bash
timoni bundle delete -f timoni.cue
kubectl delete namespace demo-app-01
```

## Advantages over Module-Only Approach

1. **Simplified operations**: One command deploys the entire stack
2. **Configuration reuse**: Global values shared across instances
3. **Consistent state**: All components deployed together
4. **Better for GitOps**: Single file defines entire application
5. **Easier rollbacks**: Roll back entire stack at once
6. **Dependency management**: Implicitly managed through bundle order

## Adding More Modules

To extend this bundle (e.g., add RBAC), simply add another instance:

```cue
bundle: {
  instances: {
    // ... existing instances ...
    
    "demo-app-01-rbac": {
      module: {
        url:     "oci://catalina.azurecr.io/rbac"
        version: "1.0.0"
      }
      namespace: "demo-app-01"
      values: {
        serviceAccountName: "demo-app-01-backend"
        // ... RBAC configuration
      }
    }
  }
}
```

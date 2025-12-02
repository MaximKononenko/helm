# Demo 1: Using Timoni Module Only

This demo shows how to deploy a single application instance using a Timoni module directly.

## Overview

- **Approach**: Single module instance deployment
- **Module**: `oci://catalina.azurecr.io/classic-deployment:0.2.3`
- **Use case**: Simple deployments, testing individual components

## Deploy

```bash
# Create namespace
kubectl create namespace demo-app-01

# Apply the module instance
timoni apply demo-app-01-backend \
  -n demo-app-01 \
  -f values.cue \
  oci://catalina.azurecr.io/classic-deployment \
  --version 0.2.3
```

## Override image tag

```bash
timoni apply demo-app-01-backend \
  -n demo-app-01 \
  -f values.cue \
  --set image.tag=v1.2.3 \
  oci://catalina.azurecr.io/classic-deployment \
  --version 0.2.3
```

## Inspect

```bash
# Show what would be deployed
timoni build demo-app-01-backend \
  -n demo-app-01 \
  -f values.cue \
  oci://catalina.azurecr.io/classic-deployment \
  --version 0.2.3

# Check deployed resources
timoni inspect resources demo-app-01-backend -n demo-app-01
```

## Clean up

```bash
timoni delete demo-app-01-backend -n demo-app-01
kubectl delete namespace demo-app-01
```

## Limitations

- Each component must be deployed separately
- No shared configuration between components
- Manual coordination of related resources
- More commands to manage multi-component applications

# Timoni Deployment Demos for demo-app-01

This directory contains two approaches for deploying applications with Timoni.

## Demos

### 1. Module-Only Deployment
**Location**: `1-module-only/`

Single module instance deployment showing the basic Timoni usage pattern.

**When to use**:
- Simple, single-component deployments
- Testing individual modules
- Quick prototyping
- Independent component lifecycle management

**Pros**:
- Simple and straightforward
- Fine-grained control per instance
- Minimal configuration

**Cons**:
- Manual coordination of multiple components
- Repetitive configuration
- More commands to manage complex apps

### 2. Bundle Deployment
**Location**: `2-bundle/`

Multi-module bundle deployment demonstrating coordinated application stacks.

**When to use**:
- Multi-component applications (frontend + backend)
- Shared configuration across components
- GitOps workflows
- Production deployments

**Pros**:
- Single-command deployment
- Shared configuration (global values)
- Atomic updates
- Better for complex applications
- Easier to version control

**Cons**:
- Slightly more complex configuration
- All components deployed together

## Quick Start

```bash
# Demo 1: Module only
cd 1-module-only
kubectl create namespace demo-app-01
timoni apply demo-app-01-backend -n demo-app-01 -f values.cue \
  oci://catalina.azurecr.io/classic-deployment:0.2.3

# Demo 2: Bundle
cd ../2-bundle
kubectl create namespace demo-app-01
timoni bundle apply -f timoni.cue
```

## Comparison

| Feature | Module-Only | Bundle |
|---------|-------------|--------|
| Deployment command | One per component | Single command |
| Configuration sharing | No | Yes (global values) |
| Multi-component support | Manual | Built-in |
| GitOps friendly | Moderate | Excellent |
| Complexity | Low | Medium |
| Best for | Simple apps | Complex apps |

## References

- [Timoni Documentation](https://timoni.sh/)
- [Bundle Specification](https://timoni.sh/bundle/)
- [Module Development](https://timoni.sh/module/)

# Azure Service Operator v2 (ASO2) CRDs

This directory manages ASO2 Custom Resource Definitions for the platform.

## Structure

```
helm/aso2/
├── azureserviceoperator_customresourcedefinitions_v2.16.0.yaml  # Complete CRD bundle (reference)
├── live/                                                        # Applied CRDs to management cluster
│   ├── vm-crds.yaml        # VirtualMachine and NetworkInterface
│   ├── aks-crds.yaml       # ManagedCluster and related resources
│   └── disk-crd.yaml       # Disk (for data disk management)
└── README.md
```

## Applied CRDs

The `live/` folder contains CRDs currently applied to the management cluster (`aks-prd-eastus2-management`).

### VM Infrastructure (vm-crds.yaml)
- `virtualmachines.compute.azure.com` - Virtual Machine management
- `networkinterfaces.network.azure.com` - Network Interface management

### AKS Infrastructure (aks-crds.yaml)
- `managedclusters.containerservice.azure.com` - AKS cluster management
- Additional AKS-related resources

### Disk Management (disk-crd.yaml)
- `disks.compute.azure.com` - Managed Disk as separate resource
- Used for data disks that need independent lifecycle

## Usage

### Apply All Live CRDs
```bash
kubectl apply -f helm/aso2/live/
```

### Apply Specific CRD Set
```bash
# VM infrastructure only
kubectl apply -f helm/aso2/live/vm-crds.yaml

# AKS infrastructure only
kubectl apply -f helm/aso2/live/aks-crds.yaml

# Disk management
kubectl apply -f helm/aso2/live/disk-crd.yaml
```

### Extract New CRD from Bundle
```bash
# Find the CRD in the bundle file
grep -n "kind: CustomResourceDefinition" helm/aso2/azureserviceoperator_customresourcedefinitions_v2.16.0.yaml

# Extract specific CRD (example for line 12345 to next ---)
awk 'NR>=12345 && /^---$/{exit} NR>=12345{print}' \
  helm/aso2/azureserviceoperator_customresourcedefinitions_v2.16.0.yaml \
  > helm/aso2/live/new-resource.yaml
```

## Version

- **ASO2 Version**: v2.16.0
- **Release Date**: November 2024
- **Source**: https://github.com/Azure/azure-service-operator/releases/tag/v2.16.0

## Notes

- Original demo CRD files remain in `helm/timoni/modules/infra/*/aso-crds.yaml` for showcase purposes
- Always test new CRDs in dev environment before applying to production clusters
- CRDs are cluster-scoped resources (no namespace)
- Deleting a CRD will delete all custom resources of that type!

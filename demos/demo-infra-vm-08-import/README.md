# Demo 08: Importing Existing VMs (Brownfield Migration)

This demo shows how to import existing Azure VMs into KubeVela + ASO management without recreation.

## Overview

Importing (or "adopting") existing infrastructure is a critical capability for brownfield environments. This demo covers multiple scenarios and approaches, broken down into progressive substeps.

## Prerequisites

- Existing VM in Azure
- `asoctl` CLI installed
- ASO credentials configured

## Import Workflow

### Step 1: Export existing VM configuration

```bash
# Find VM ARM ID
VM_ARM_ID=$(az vm show \
  --resource-group rg-existing \
  --name existing-vm-01 \
  --query id -o tsv)

# Import VM configuration
asoctl import azure-resource "$VM_ARM_ID" \
  --output imported-vm.yaml \
  --namespace azureserviceoperator-system \
  --annotation serviceoperator.azure.com/reconcile-policy=detach-on-delete \
  --verbose
```

**Output example:**
```
INF Imported kind=VirtualMachine.compute.azure.com name=existing-vm-01
INF Imported kind=NetworkInterface.network.azure.com name=existing-vm-01-nic
INF Imported kind=Disk.compute.azure.com name=existing-vm-01-osdisk
INF Imported kind=Disk.compute.azure.com name=existing-vm-01-datadisk-0
INF Writing to file path=imported-vm.yaml
```

### Step 2: Review generated YAML

The `imported-vm.yaml` contains:
- VM resource with current configuration
- Network interface
- OS disk
- Data disks (if any)
- All current tags and settings

### Step 3: Convert to KubeVela Application (Optional)

You have two options:

#### Option A: Apply raw ASO resources directly
```bash
kubectl apply -f imported-vm.yaml
```

#### Option B: Wrap in KubeVela Application

Create `vm-adopted.yaml`:
```yaml
apiVersion: core.oam.dev/v1beta1
kind: Application
metadata:
  name: adopted-vm-01
  namespace: azureserviceoperator-system
spec:
  components:
    # Use type: raw to wrap existing ASO resources
    - name: existing-vm
      type: raw
      properties:
        apiVersion: compute.azure.com/v1api20220301
        kind: VirtualMachine
        # Copy spec from imported-vm.yaml
        
    - name: existing-vm-nic
      type: raw
      properties:
        apiVersion: network.azure.com/v1api20240301
        kind: NetworkInterface
        # Copy spec from imported-vm.yaml
```

### Step 4: Apply and verify

```bash
# Apply the Application
kubectl apply -f vm-adopted.yaml

# Verify adoption (no Azure changes should occur)
kubectl get application.core.oam.dev adopted-vm-01 -n azureserviceoperator-system -w

# Check conditions - should show "Ready" without recreating
kubectl get virtualmachine.compute.azure.com existing-vm-01 -n azureserviceoperator-system -o yaml | grep -A 10 conditions:
```

## Important Notes

### Adoption Behavior

1. **Name Matching**: ASO matches resources by `metadata.name` + `spec.owner.armId`
2. **No Downtime**: Adoption doesn't recreate resources
3. **Configuration Drift**: If imported config differs from Azure, ASO will update Azure to match

### Reconcile Policy Options

**Default (no annotation)**:
- ASO manages resource
- Deleting CR **deletes Azure resource**

**With `detach-on-delete`**:
```yaml
metadata:
  annotations:
    serviceoperator.azure.com/reconcile-policy: detach-on-delete
```
- ASO manages resource
- Deleting CR **leaves Azure resource intact**

### Migration from ComponentDefinition

If you want to adopt an existing VM and **then** use our ComponentDefinition for future management:

```bash
# Step 1: Import existing VM
asoctl import azure-resource "$VM_ARM_ID" --output temp.yaml

# Step 2: Extract configuration details
VM_SIZE=$(yq '.spec.hardwareProfile.vmSize' temp.yaml)
DISK_SIZE=$(yq '.spec.storageProfile.osDisk.diskSizeGB' temp.yaml)
# ... extract other settings

# Step 3: Create Application using ComponentDefinition
cat > vm-with-definition.yaml <<EOF
apiVersion: core.oam.dev/v1beta1
kind: Application
metadata:
  name: adopted-vm-01
  namespace: azureserviceoperator-system
spec:
  components:
    - name: existing-vm
      type: azure-vm
      properties:
        subscriptionId: "..."
        resourceGroup: "rg-existing"
        vmName: "existing-vm-01"
        vmSize: "medium"  # Map from $VM_SIZE
        osDiskSizeGB: 128
        # ... other properties
        tags:
          ImportedFrom: "manual-creation"
          ManagedBy: "kubevela"
EOF

# Step 4: Apply (ASO will adopt, not recreate)
kubectl apply -f vm-with-definition.yaml
```

## Use Cases

### 1. **Brownfield Migration**
- Adopt existing Terraform/ARM-managed VMs
- Transition to GitOps workflow
- No downtime during migration

### 2. **Disaster Recovery**
- Import production VMs for configuration backup
- Version control infrastructure state
- Quick restore from Git

### 3. **Compliance Audit**
- Import all VMs in subscription
- Compare against compliance policies
- Detect configuration drift

### 4. **Multi-Team Coordination**
- Team A creates VM manually for testing
- Team B imports and adds traits (backup, monitoring)
- Unified management without recreation

## Verification

### Check Adoption Status

```bash
# VM should show "Ready" condition
kubectl get virtualmachine.compute.azure.com -n azureserviceoperator-system

# Check Azure - no changes should be detected
az vm show --resource-group rg-existing --name existing-vm-01 --query provisioningState
```

### Test Management

```bash
# Update tags via KubeVela
kubectl patch application adopted-vm-01 -n azureserviceoperator-system --type=merge -p '
{
  "spec": {
    "components": [{
      "properties": {
        "spec": {
          "tags": {
            "NewTag": "test-value"
          }
        }
      }
    }]
  }
}'

# Verify tag appears in Azure
az vm show --resource-group rg-existing --name existing-vm-01 --query tags
```

## Limitations

1. **Resource State**: Imported resources must exist in Azure before adoption
2. **Naming**: ASO resource name must match Azure resource name
3. **Dependencies**: All referenced resources (VNet, subnets) must be accessible
4. **Configuration Drift**: Import captures current state, which may differ from original intent

## Comparison: Terraform Import vs ASO Adoption

| Feature | Terraform Import | ASO Adoption |
|---------|------------------|--------------|
| **Command** | `terraform import` + manual config | `asoctl import` (auto-generates config) |
| **Recreation Risk** | High (if config doesn't match) | Low (ASO matches by ARM ID) |
| **Child Resources** | Manual (one by one) | Automatic (discovers dependencies) |
| **State Management** | Separate state file | Kubernetes etcd |
| **GitOps Ready** | Requires state backend setup | Native Kubernetes resources |
| **Drift Detection** | `terraform plan` | ASO reconciliation loop |

## Next Steps (Substeps for Demo 08)

This demo can be expanded into multiple progressive substeps:

### 08.1: Basic Single VM Import
- **Goal**: Import one existing VM using `asoctl`
- **Skills**: Basic adoption, reconcile-policy annotation
- **Deliverable**: Single VM managed by ASO without recreation

### 08.2: Import with Dependencies
- **Goal**: Import VM with all related resources (NICs, Disks, NSGs)
- **Skills**: Dependency discovery, resource graph import
- **Deliverable**: Complete VM infrastructure stack imported

### 08.3: Wrap in KubeVela Application
- **Goal**: Convert raw ASO resources to KubeVela Application
- **Skills**: `type: raw` components, Application composition
- **Deliverable**: Imported VM managed via KubeVela GitOps

### 08.4: Apply Traits to Imported VMs
- **Goal**: Add backup, monitoring, security traits to existing VMs
- **Skills**: Trait composition, ConfigMap generation
- **Deliverable**: Imported VM with full trait stack (no recreation)

### 08.5: Bulk Import Automation
- **Goal**: Import entire resource groups or subscriptions
- **Skills**: Scripting with `az` + `asoctl`, batch processing
- **Deliverable**: Script to import 100+ VMs automatically

### 08.6: Migration from Terraform
- **Goal**: Import Terraform-managed VMs and remove from tfstate
- **Skills**: Terraform state manipulation, KubeVela migration
- **Deliverable**: Complete Terraform → KubeVela migration path

### 08.7: Configuration Drift Detection
- **Goal**: Compare imported config vs Azure reality, detect drift
- **Skills**: ASO reconciliation, compliance scanning
- **Deliverable**: Drift detection dashboard + auto-remediation

### 08.8: Import Templates and Documentation
- **Goal**: Create reusable import templates for common scenarios
- **Skills**: Templating, documentation as code
- **Deliverable**: Import playbook for production use

## Implementation Priority

**Phase 1 (Immediate)**: 08.1, 08.2, 08.3
**Phase 2 (Short-term)**: 08.4, 08.5
**Phase 3 (Long-term)**: 08.6, 08.7, 08.8

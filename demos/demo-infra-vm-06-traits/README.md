# Demo 6: Infrastructure Traits

This demo showcases **Traits** - the OAM concept for adding cross-cutting concerns to components without modifying the component definition itself.

## What are Traits?

Traits are reusable operational behaviors that can be attached to any workload. They enable:
- **Separation of Concerns**: Keep infrastructure logic separate from operational policies
- **Policy Enforcement**: Apply organization-wide standards consistently
- **Composability**: Mix and match policies as needed
- **Reusability**: Define once, apply everywhere

## Available Traits

### 1. Backup Policy (`backup-policy`)
Configures backup settings for the VM.

**Parameters:**
- `enabled`: Enable/disable backups (default: "true")
- `retentionDays`: Backup retention period (default: 30)
- `schedule`: Cron schedule for backups (default: "0 2 * * *")
- `vaultName`: Backup vault name (optional)

**What it does:**
- Adds backup-related tags to the VM
- Creates a ConfigMap with backup configuration
- Can be integrated with Azure Backup service

### 2. Cost Tracking (`cost-tracking`)
Adds cost allocation and chargeback tags.

**Parameters:**
- `costCenter`: Cost center code (required)
- `department`: Department name (required)
- `project`: Project code (required)
- `billingCode`: Custom billing code (optional, auto-generated)
- `approver`: Budget approver email (optional)

**What it does:**
- Adds comprehensive cost tracking tags
- Enables Azure Cost Management queries by department/project
- Supports chargeback and showback reporting

### 3. Security Baseline (`security-baseline`)
Enforces security and compliance settings.

**Parameters:**
- `securityLevel`: public, internal, confidential, restricted (default: internal)
- `complianceFramework`: none, pci-dss, hipaa, sox, gdpr (default: none)
- `dataClassification`: Data classification level (default: internal)
- `patchingSchedule`: immediate, weekly, monthly (default: weekly)
- `securityContact`: Security team contact (optional)

**What it does:**
- Adds security and compliance tags
- Creates ConfigMap for security scanning tools
- Enables compliance reporting

### 4. Monitoring (`monitoring`)
Configures monitoring and alerting.

**Parameters:**
- `enabled`: Enable monitoring (default: true)
- `alertSeverity`: critical, high, medium, low (default: medium)
- `alertContact`: Alert destination email/webhook (required)
- `metricsRetentionDays`: Metrics retention period (default: 90)
- `monitoringStack`: datadog, prometheus, both (default: datadog)
- `datadogEnv`: Datadog environment tag (default: production)
- `cpuThreshold`: CPU alert threshold % (default: 85)
- `memoryThreshold`: Memory alert threshold % (default: 90)
- `diskThreshold`: Disk alert threshold % (default: 85)

**What it does:**
- Adds monitoring tags
- Creates ConfigMap with alert thresholds
- Integrates with Datadog APM and Prometheus/Grafana

## Prerequisites

```bash
# 1. Apply TraitDefinitions
kubectl apply -f ../../vela/definitions/backup-policy-trait.yaml
kubectl apply -f ../../vela/definitions/cost-tracking-trait.yaml
kubectl apply -f ../../vela/definitions/security-baseline-trait.yaml
kubectl apply -f ../../vela/definitions/monitoring-trait.yaml

# 2. Verify traits are available
kubectl get traitdefinition -n vela-system
```

## Demo 1: Full Traits Stack

Apply all traits to a production VM:

```bash
# 1. Review the Application with all traits
cat vm-with-all-traits.yaml

# 2. Create VM with all traits
kubectl apply -f vm-with-all-traits.yaml

# 3. Monitor Application status
kubectl get application.core.oam.dev vm-with-traits -n azureserviceoperator-system
kubectl describe application.core.oam.dev vm-with-traits -n azureserviceoperator-system

# 4. Check generated ConfigMaps (trait outputs)
kubectl get configmap -n azureserviceoperator-system | grep vm-with-traits

# View backup configuration
kubectl get configmap vm-with-traits-backup-config -n azureserviceoperator-system -o yaml

# View security configuration
kubectl get configmap vm-with-traits-security-config -n azureserviceoperator-system -o yaml

# View alert configuration
kubectl get configmap vm-with-traits-alert-config -n azureserviceoperator-system -o yaml

# 5. Verify in Azure (check tags)
az vm show \
  --resource-group rg-tst-eastus-istio-compute \
  --name vm-traits-demo-01 \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c \
  --query '{name:name, size:hardwareProfile.vmSize, tags:tags}' \
  -o json | jq .tags

# Expected tags:
# - BackupEnabled, BackupRetention, BackupSchedule, BackupVault
# - CostCenter, Department, Project, BillingCode, Approver
# - SecurityLevel, ComplianceFramework, DataClassification, PatchingSchedule
# - MonitoringEnabled, AlertSeverity, AlertContact, MetricsRetention
# - Plus user tags: Owner, Purpose
# - Plus platform tags: ManagedBy, Environment

# 6. Cleanup
kubectl delete application.core.oam.dev vm-with-traits -n azureserviceoperator-system
```

## Demo 2: Minimal Traits (Developer Use Case)

Developer creates VM with only cost tracking:

```bash
# 1. Review minimal configuration
cat vm-with-minimal-traits.yaml

# 2. Create VM with cost tracking only
kubectl apply -f vm-with-minimal-traits.yaml

# 3. Monitor
kubectl get application.core.oam.dev vm-minimal-traits -n azureserviceoperator-system

# 4. Verify tags in Azure
az vm show \
  --resource-group rg-tst-eastus-istio-compute \
  --name vm-traits-minimal-01 \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c \
  --query 'tags' \
  -o json

# 5. Cleanup
kubectl delete application.core.oam.dev vm-minimal-traits -n azureserviceoperator-system
```

## Demo 3: VM with Data Disks (Database Use Case)

Create VM with additional data disks for database workload:

```bash
# 1. Review configuration with data disks
cat vm-with-data-disks.yaml

# Application has 1 component with dataDisks parameter:
# - vm: The virtual machine with 2 data disks
#   - Disk 0: 256GB Premium_LRS for database files (ReadWrite caching)
#   - Disk 1: 128GB StandardSSD_LRS for logs (No caching)
# Data disks are automatically created and attached!

# 2. Create VM with data disks
kubectl apply -f vm-with-data-disks.yaml

# 3. Monitor Application
kubectl get application.core.oam.dev vm-with-disks -n azureserviceoperator-system

# 4. Check all resources (VM + Disks)
kubectl get virtualmachine,disk -n azureserviceoperator-system | grep vm-disks-demo-01

# 5. Verify VM in Azure
az vm show \
  --resource-group rg-tst-eastus-istio-compute \
  --name vm-disks-demo-01 \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c \
  --query '{name:name, size:hardwareProfile.vmSize, tags:tags}' \
  -o json

# 6. Verify disks in Azure
az disk list \
  --resource-group rg-tst-eastus-istio-compute \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c \
  --query "[?contains(name, 'vm-disks-demo-01-datadisk')].{name:name, sizeGB:diskSizeGb, sku:sku.name, state:diskState, tags:tags}" \
  -o table

# Expected disks:
# - vm-disks-demo-01-osdisk (30GB OS disk)
# - vm-disks-demo-01-datadisk-0 (256GB Premium_LRS) ✅ Auto-created & attached
# - vm-disks-demo-01-datadisk-1 (128GB StandardSSD_LRS) ✅ Auto-created & attached

# 7. Wait for VM provisioning to complete (5-10 minutes)
sleep 300

# 8. Verify disks are automatically attached
az vm show \
  --resource-group rg-tst-eastus-istio-compute \
  --name vm-disks-demo-01 \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c \
  --query 'storageProfile.dataDisks[].{name:name, lun:lun, sizeGB:diskSizeGb, caching:caching}' \
  -o table

# 9. Cleanup
kubectl delete application.core.oam.dev vm-with-disks -n azureserviceoperator-system

# Note: All resources (VM + Disks) are automatically deleted
# Data disks have deleteOption: Delete set in the VM storageProfile
# This ensures no orphaned disks remain
```

### Key Points: Data Disks

**Multi-Component Applications**:
- KubeVela Applications can have multiple components
- Each component can be a different resource type
- Use `type: raw` for native Kubernetes/ASO2 resources

**Disk Provisioning**:
```yaml
components:
  - name: vm
    type: azure-vm
    properties:
      vmName: "my-vm"
      vmSize: "medium"
      # ... other properties ...
      
      # Data disks (automatically created and attached)
      dataDisks:
        - sizeGB: 256
          storageAccountType: Premium_LRS
          caching: ReadWrite      # Database workload
        
        - sizeGB: 128
          storageAccountType: StandardSSD_LRS
          caching: None           # Log files
```

**How It Works**:
- ComponentDefinition automatically creates Disk resources via `outputs`
- Disks are named: `{vmName}-datadisk-{index}` (e.g., `my-vm-datadisk-0`)
- LUN (Logical Unit Number) assigned automatically by array index
- Disks are attached with `createOption: "Attach"` and `deleteOption: "Delete"`
- Tags from VM (including traits) are inherited by disks
- Cleanup: All disks deleted automatically when VM is deleted

**Caching Policies**:
- `ReadWrite` (default): Best for database files and application data
- `ReadOnly`: Best for read-heavy workloads
- `None`: Best for log files and sequential writes

**Tag Inheritance**:
- Data disks inherit tags from Application properties
- Cost tracking tags applied to both VM and disks
- Enables proper cost allocation per workload

## REST API Integration

Traits work seamlessly with REST API calls:

```bash
# Get API token
TOKEN=$(kubectl create token platform-api-user \
  --namespace azureserviceoperator-system \
  --duration=10m)

API_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

# Create VM with traits via POST
curl -k -X POST \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d @vm-with-all-traits.json \
  "${API_SERVER}/apis/core.oam.dev/v1beta1/namespaces/azureserviceoperator-system/applications"

# Update traits via PATCH
curl -k -X PATCH \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/merge-patch+json" \
  -d '{"spec":{"components":[{"traits":[{"type":"monitoring","properties":{"alertSeverity":"critical"}}]}]}}' \
  "${API_SERVER}/apis/core.oam.dev/v1beta1/namespaces/azureserviceoperator-system/applications/vm-with-traits"
```

## Key Benefits

### 1. Separation of Concerns
- **Developers** focus on VM specs (size, network, storage)
- **Platform Team** enforces policies via traits (backup, security, cost)
- **Security Team** defines compliance requirements
- **Finance Team** controls cost allocation

### 2. Policy Enforcement
```yaml
# Platform admin creates TraitDefinition once
# Developers must apply required traits

# Example: Mandate cost-tracking for all VMs
apiVersion: core.oam.dev/v1beta1
kind: Policy
metadata:
  name: require-cost-tracking
spec:
  type: override
  properties:
    components:
      - type: azure-vm
        traits:
          - type: cost-tracking  # Always applied
```

### 3. Dynamic Configuration
Traits can use environment-specific values:

```yaml
# Production: Strict policies
traits:
  - type: backup-policy
    properties:
      retentionDays: 90
      schedule: "0 */4 * * *"  # Every 4 hours

  - type: security-baseline
    properties:
      securityLevel: "restricted"
      complianceFramework: "pci-dss"

# Development: Relaxed policies
traits:
  - type: backup-policy
    properties:
      retentionDays: 7
      schedule: "0 2 * * *"  # Daily
```

### 4. Audit and Compliance
All trait configurations are stored in Kubernetes:

```bash
# Audit: Who created what with which policies?
kubectl get application -n azureserviceoperator-system -o json | \
  jq '.items[] | {name: .metadata.name, owner: .metadata.labels.owner, traits: .spec.components[].traits[].type}'

# Compliance report: Which VMs have backup enabled?
kubectl get application -n azureserviceoperator-system -o json | \
  jq '.items[] | select(.spec.components[].traits[]? | .type == "backup-policy")'
```

## Use Cases

### Platform Self-Service Portal
Your UI can present traits as checkboxes:

```
┌─────────────────────────────────────┐
│ Create Virtual Machine              │
├─────────────────────────────────────┤
│ Name: [vm-user-123            ]     │
│ Size: [Standard_B2s ▼]              │
│                                     │
│ Data Disks:                         │
│ ☑ Add data disk 1                   │
│   Size: [256] GB                    │
│   Type: [Premium_LRS ▼]             │
│   Caching: [ReadWrite ▼]            │
│                                     │
│ ☐ Add data disk 2                   │
│   Size: [128] GB                    │
│   Type: [StandardSSD_LRS ▼]         │
│   Caching: [None ▼]                 │
│                                     │
│ [+ Add another disk]                │
│                                     │
│ Policies:                           │
│ ☑ Enable Backups                    │
│   Retention: [30] days              │
│                                     │
│ ☑ Cost Tracking (required)          │
│   Cost Center: [ENG-001      ]      │
│   Project: [feature-xyz      ]      │
│                                     │
│ ☑ Security Baseline                 │
│   Level: [Internal ▼]               │
│                                     │
│ ☐ Advanced Monitoring               │
│                                     │
│         [Cancel]  [Create VM]       │
└─────────────────────────────────────┘
```

### Environment-Based Defaults
```typescript
// UI logic
const getTraitsForEnvironment = (env: string) => {
  if (env === 'production') {
    return [
      { type: 'backup-policy', properties: { retentionDays: 90 } },
      { type: 'security-baseline', properties: { securityLevel: 'restricted' } },
      { type: 'monitoring', properties: { alertSeverity: 'critical' } },
    ];
  }
  return [
    { type: 'backup-policy', properties: { retentionDays: 7 } },
  ];
};
```

## Comparison: With vs Without Traits

### Without Traits (ComponentDefinition does everything)
```yaml
# ComponentDefinition azure-vm hardcodes backup tags
template: |-
  output: {
    spec: {
      tags: {
        BackupEnabled: "true"  # ❌ Everyone gets backups
        BackupRetention: "30"  # ❌ Fixed value
        # ...
      }
    }
  }

# Result: No flexibility, must edit ComponentDefinition for changes
```

### With Traits (Composable policies)
```yaml
# ComponentDefinition focuses on VM logic
# Traits add operational concerns

# User 1: Production VM with all policies
traits:
  - backup-policy
  - cost-tracking
  - security-baseline
  - monitoring

# User 2: Dev VM with minimal policies
traits:
  - cost-tracking  # Only billing required

# User 3: High-security VM
traits:
  - security-baseline:
      securityLevel: restricted
      complianceFramework: pci-dss
```

## Next Steps

1. ✅ **Traits Demonstrated**: Backup, Cost, Security, Monitoring
2. [ ] **Policy Enforcement**: Create admission webhook to require traits
3. [ ] **Workflow Integration**: Approval process for restricted security levels
4. [ ] **Cost Estimation**: Calculate monthly cost based on vmSize + backup + monitoring
5. [ ] **Azure Integration**: Connect trait ConfigMaps to Azure services
   - Backup vault automation
   - Log Analytics workspace configuration
   - Azure Monitor alert rules
6. [ ] **UI Development**: Build React/Angular forms with trait configuration

## Files Reference

- **TraitDefinitions**:
  - `helm/vela/definitions/backup-policy-trait.yaml`
  - `helm/vela/definitions/cost-tracking-trait.yaml`
  - `helm/vela/definitions/security-baseline-trait.yaml`
  - `helm/vela/definitions/monitoring-trait.yaml`

- **Applications**:
  - `helm/demos/demo-infra-vm-05-traits/vm-with-all-traits.yaml`
  - `helm/demos/demo-infra-vm-05-traits/vm-with-minimal-traits.yaml`

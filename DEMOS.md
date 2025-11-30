# Platform Engineering Demos

This document showcases different approaches for infrastructure provisioning and application deployment using our platform stack.

**Stack Overview:**
- **Infrastructure Provider**: Azure Service Operator v2 (ASO2)
- **Orchestrator**: KubeVela (OAM)
- **Packaging**: Timoni (CUE)
- **GitOps**: ArgoCD
- **Management Cluster**: `aks-prd-eastus2-management`

---

## Demo 1: Application Deployment with Timoni

**Use Case**: Developer deploys a pre-packaged application using GitOps

**Location**: `helm/timoni/projects/demo-app-01/`

### Architecture
```
Git → ArgoCD → Timoni Module (OCI) → Kubernetes Workloads
```

### Commands

```bash
# 1. Navigate to project
cd helm/timoni/projects/demo-app-01

# 2. Build and inspect (dry-run)
timoni bundle build -f bundle.cue

# 3. Deploy application
timoni bundle apply -f bundle.cue

# 4. Check deployment
kubectl get pods -n demo-app-01
kubectl get svc -n demo-app-01

# 5. Cleanup
timoni bundle delete -f bundle.cue
```

### Key Features
- ✅ Pre-built module from OCI registry
- ✅ Version-controlled deployments
- ✅ CUE-based configuration
- ✅ GitOps-ready (ArgoCD can apply)

---

## Demo 2: Infrastructure (VM) with Timoni Only

**Use Case**: Platform Engineer tests ASO2 integration with simple infrastructure

**Location**: `helm/demos/demo-infra-vm-01-timoni/`

### Architecture
```
Timoni CLI → ASO2 CRDs → Azure API → Virtual Machine
```

### Commands

```bash
# 1. Navigate to demo
cd helm/demos/demo-infra-vm-01-timoni

# 2. Review configuration
cat bundle.cue

# 2. Login to ACR (required for pulling OCI modules)
az acr login --name catalina

# 3. Build and validate (dry-run)
timoni bundle build -f bundle.cue

# 4. Deploy VM infrastructure
timoni bundle apply -f bundle.cue

# 5. Monitor ASO2 resources
kubectl get virtualmachine,networkinterface -n azureserviceoperator-system -w

# 6. Verify in Azure
az vm show \
  --resource-group rg-tst-eastus-istio-compute \
  --name vm-timoni-test-01 \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c \
  --query '{name:name, state:provisioningState, size:hardwareProfile.vmSize}' \
  -o table

# 7. Cleanup
timoni bundle delete -f bundle.cue

# 8. Verify deletion in Azure
az vm show \
  --resource-group rg-tst-eastus-istio-compute \
  --name vm-timoni-test-01 \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c
# Should return: ResourceNotFound
```

### Key Features
- ✅ Direct ASO2 resource management
- ✅ Brownfield networking (existing VNet/Subnet)
- ✅ No public IP (security-first)
- ✅ Full CUD lifecycle
- ✅ Simple CLI workflow

### Limitations
- ⚠️ CLI-driven (not API-driven)
- ⚠️ No OAM abstraction https://oam.dev/
- ⚠️ No policy enforcement
- ⚠️ Manual execution required

---

## Demo 3: Infrastructure (VM) with KubeVela + Timoni

**Use Case**: Orchestrated infrastructure provisioning with KubeVela wrapping Timoni

**Location**: `helm/demos/demo-infra-vm-02-vela-timoni/`

### Architecture
```
KubeVela Application → Job → Timoni CLI → ASO2 CRDs → Azure API → VM
```

### Prerequisites

```bash
# 1. Ensure ComponentDefinition is installed
kubectl get componentdefinition timoni-module -n vela-system

# 2. Ensure RBAC is configured
kubectl get serviceaccount vela-timoni-runner -n azureserviceoperator-system
kubectl get clusterrole timoni-runner-role

# 3. Ensure ACR credentials are available
kubectl get secret acr-catalina -n azureserviceoperator-system
```

### Commands

```bash
# 1. Navigate to demo
cd helm/demos/demo-infra-vm-02-vela-timoni

# 2. Review Application
cat test-vm.yaml

# 3. Apply Application
kubectl apply -f test-vm.yaml

# 4. Monitor Application status
kubectl get application.core.oam.dev test-vm -n azureserviceoperator-system

# 5. Check Job execution
kubectl get job linux-vm -n azureserviceoperator-system
kubectl logs -n azureserviceoperator-system job/linux-vm

# 6. Monitor ASO2 resources
kubectl get virtualmachine,networkinterface -n azureserviceoperator-system

# 7. Verify in Azure
az vm show \
  --resource-group rg-tst-eastus-istio-compute \
  --name vm-vela-test-01 \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c \
  --query '{name:name, state:provisioningState, size:hardwareProfile.vmSize}' \
  -o table

# 8. Cleanup (two steps required)
# Step 1: Delete KubeVela Application
kubectl delete application.core.oam.dev test-vm -n azureserviceoperator-system

# Step 2: Delete Timoni instance (manual cleanup)
timoni delete linux-vm -n azureserviceoperator-system

# 9. Verify deletion
az vm show \
  --resource-group rg-tst-eastus-istio-compute \
  --name vm-vela-test-01 \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c
# Should return: ResourceNotFound
```

### Key Features
- ✅ KubeVela orchestration
- ✅ Job-based workflow
- ✅ Docker config mounting for ACR
- ✅ CUE values format (critical discovery!)

### Limitations
- ⚠️ **Create-only lifecycle** - No automatic updates/deletes
- ⚠️ Job overhead (image pull, pod creation)
- ⚠️ Manual cleanup required (`timoni delete`)
- ⚠️ Adds complexity without OAM benefits
- ⚠️ Not suitable for UI/API integration

### Critical Discoveries

**1. JSON values fail with "undefined value"** - Timoni requires CUE format:
```yaml
# ✅ Correct (CUE format)
values: {"key": "value", "nested": {"field": 123}}

# ❌ Incorrect (plain JSON in file)
{"key": "value", "nested": {"field": 123}}
```

**2. Disk deletion** - ASO2 requires explicit `deleteOption: "Delete"` in osDisk configuration:
```yaml
osDisk: {
  createOption: "FromImage"
  deleteOption: "Delete"  # ⚠️ Without this, disks remain orphaned!
  diskSizeGB: 30
}
```

---

## Demo 4: Infrastructure (VM) with KubeVela Native

**Use Case**: 🎯 **RECOMMENDED** - Self-service VM provisioning with OAM abstraction

**Location**: `helm/demos/demo-infra-vm-03-vela-native/`

### Architecture
```
Your UI → KubeVela API → ASO2 CRDs → Azure API → VM
```

### Prerequisites

```bash
# 1. Ensure native ComponentDefinition is installed
kubectl get componentdefinition azure-vm -n vela-system

# 2. Check CUE patterns documentation
cat helm/vela/CUE_PATTERNS.md
```

### Commands

```bash
# 1. Navigate to demo
cd helm/demos/demo-infra-vm-03-vela-native

# 2. Review Application (simplified user interface!)
cat test-vm-native.yaml

# Notice: Users only specify:
# - vmSize: "medium" (not Azure SKU!)
# - environment: "dev" (affects actual SKU selection)
# - tags (merged with platform defaults)
# - network (brownfield references)

# 3. Apply Application
kubectl apply -f test-vm-native.yaml

# 4. Monitor Application status
kubectl get application.core.oam.dev test-vm-native -n azureserviceoperator-system

# 5. Monitor ASO2 resources (created directly, no Job!)
kubectl get virtualmachine,networkinterface -n azureserviceoperator-system

# 6. Describe VM to see mapped values
kubectl describe virtualmachine vm-kubevela-native-01 -n azureserviceoperator-system

# Notice the vmSize is "Standard_B2s" (from dev/medium mapping in ComponentDefinition)

# 7. Verify in Azure
az vm show \
  --resource-group rg-tst-eastus-istio-compute \
  --name vm-kubevela-native-01 \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c \
  --query '{name:name, state:provisioningState, size:hardwareProfile.vmSize, tags:tags}' \
  -o table

# Notice tags include both user tags AND platform defaults (ManagedBy, Environment)

# 8. Test Update (change VM size)
# Edit the Application
kubectl edit application.core.oam.dev test-vm-native -n azureserviceoperator-system
# Change: vmSize: "medium" → vmSize: "large"
# Save and exit

# 9. Monitor update
kubectl get virtualmachine vm-kubevela-native-01 -n azureserviceoperator-system -w

# ASO2 will update the VM size in Azure!

# 10. Cleanup (single step!)
kubectl delete application.core.oam.dev test-vm-native -n azureserviceoperator-system

# 11. Verify ASO2 cleanup
kubectl get virtualmachine,networkinterface -n azureserviceoperator-system

# 12. Verify Azure cleanup
az vm show \
  --resource-group rg-tst-eastus-istio-compute \
  --name vm-kubevela-native-01 \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c
# Should return: ResourceNotFound
```

### Key Features
- ✅ **Full CUD lifecycle** - Create, Update, Delete all work!
- ✅ **OAM abstraction** - User-friendly interface (small/medium/large)
- ✅ **Policy enforcement** - CUE validation, regex patterns, constraints
- ✅ **Environment-aware** - Dev uses cheaper SKUs, prod uses robust SKUs
- ✅ **Tag merging** - Platform defaults + user tags
- ✅ **Conditional resources** - Public IP only if explicitly enabled
- ✅ **API-ready** - Your UI calls standard Kubernetes API
- ✅ **No Job overhead** - Direct resource management
- ✅ **Single cleanup step** - Delete Application, ASO2 cleans Azure

### CUE Pattern Examples

**1. Size Mapping**
```cue
_sizeMap: {
  small:  "Standard_B2s"
  medium: "Standard_D2s_v3"
  large:  "Standard_D4s_v3"
}

output: {
  spec: {
    hardwareProfile: {
      vmSize: _sizeMap[parameter.vmSize]
    }
  }
}
```

**2. Environment-Aware Sizing**
```cue
_envSizeMap: {
  dev: {
    small: "Standard_B1s"   // Cheaper
    medium: "Standard_B2s"
  }
  prod: {
    small: "Standard_D2s_v3"  // No B-series
    medium: "Standard_D4s_v3"
  }
}
```

**3. Tag Merging (Loop)**
```cue
_computedTags: {
  ManagedBy: "kubevela"
  Environment: parameter.environment | *"unknown"
  for k, v in parameter.tags {
    "\(k)": v
  }
}
```

**4. Conditional Resources**
```cue
if parameter.publicIP.enabled {
  outputs: publicip: {
    kind: "PublicIPAddress"
    // ...
  }
}
```

---

## Demo Comparison Matrix

| Feature | Demo 1<br/>App + Timoni | Demo 2<br/>Infra + Timoni | Demo 3<br/>Infra + KubeVela + Timoni | Demo 4<br/>Infra + KubeVela Native |
|---------|-------------------------|---------------------------|--------------------------------------|-----------------------------------|
| **Use Case** | Application deployment | Infrastructure testing | Orchestrated infra | Self-service platform |
| **Tool** | Timoni | Timoni | KubeVela + Timoni | KubeVela |
| **Execution** | CLI/ArgoCD | CLI | Job wrapper | Controller |
| **Bundles** | ✅ bundle.cue | ✅ bundle.cue | ❌ N/A | ❌ N/A |
| **Create** | ✅ | ✅ | ✅ | ✅ |
| **Update** | ✅ | ✅ | ⚠️ Manual | ✅ |
| **Delete** | ✅ | ✅ | ⚠️ Manual | ✅ |
| **OAM Abstraction** | ❌ | ❌ | ⚠️ Limited | ✅ |
| **Policy Enforcement** | ⚠️ Module-level | ⚠️ Module-level | ⚠️ Module-level | ✅ CUE validation |
| **API Integration** | ❌ CLI only | ❌ CLI only | ⚠️ Job-based | ✅ REST API |
| **Traits Support** | ❌ | ❌ | ❌ | ✅ |
| **Complexity** | Low | Low | High | Medium |
| **Best For** | Developers | Testing | ❌ Not recommended | Platform engineering |

---

## Recommended Architecture

### **For Infrastructure Provisioning** (Your Platform)
**Use Demo 4**: KubeVela Native with ASO2

```
Your UI → Kubernetes API (REST)
    ↓
KubeVela Application
    ↓
ComponentDefinition (CUE template)
    ↓
ASO2 CRDs
    ↓
Azure Resources
```

**Why:**
- Full lifecycle management
- Policy enforcement
- User-friendly abstractions
- API-driven (no CLI)
- Extensible with Traits

### **For Application Deployment** (Developers)
**Use Demo 1**: Timoni + ArgoCD

```
Git Repository
    ↓
ArgoCD (GitOps)
    ↓
Timoni Modules (OCI)
    ↓
Kubernetes Workloads
```

**Why:**
- Version-controlled modules
- GitOps pull model
- Reusable patterns
- No infrastructure access

---

## API Integration Example (Demo 4)

Your UI would make standard Kubernetes API calls:

```bash
# Create VM (what your UI sends)
POST https://k8s-api/apis/core.oam.dev/v1beta1/namespaces/azureserviceoperator-system/applications
Content-Type: application/json

{
  "apiVersion": "core.oam.dev/v1beta1",
  "kind": "Application",
  "metadata": {
    "name": "user-vm-123"
  },
  "spec": {
    "components": [{
      "name": "vm",
      "type": "azure-vm",
      "properties": {
        "vmName": "user-vm-123",
        "vmSize": "medium",
        "environment": "dev",
        "resourceGroup": "rg-user-resources",
        "network": {
          "vnetResourceGroup": "rg-shared-network",
          "vnetName": "vn-shared",
          "subnetName": "sn-vms"
        },
        "tags": {
          "Owner": "john.doe@company.com",
          "CostCenter": "engineering"
        }
      }
    }]
  }
}

# Get VM status
GET https://k8s-api/apis/core.oam.dev/v1beta1/namespaces/azureserviceoperator-system/applications/user-vm-123

# Update VM (resize)
PATCH https://k8s-api/apis/core.oam.dev/v1beta1/namespaces/azureserviceoperator-system/applications/user-vm-123
{
  "spec": {
    "components": [{
      "properties": {
        "vmSize": "large"  // User clicks "Upgrade" button
      }
    }]
  }
}

# Delete VM
DELETE https://k8s-api/apis/core.oam.dev/v1beta1/namespaces/azureserviceoperator-system/applications/user-vm-123
```

No CLI required - pure API calls!

---

## Next Steps

1. **Complete Demo 4 Testing**: Deploy and validate full CUD lifecycle
2. **Add Traits**: Backup policies, cost tagging, security baselines
3. **Create UI Mockups**: Show how users interact with the platform
4. **Document RBAC**: Limit which users can provision in which RGs
5. **Cost Estimation**: Pre-deployment cost calculation
6. **Approval Workflow**: Multi-stage approvals for expensive resources

---

## Files Reference

- **ComponentDefinitions**:
  - `helm/vela/definitions/timoni-module.yaml` (Job wrapper - Demo 3)
  - `helm/vela/definitions/azure-vm.yaml` (Native ASO2 - Demo 4)
  - `helm/vela/definitions/rbac.yaml` (ServiceAccount and permissions)

- **Applications**:
  - `helm/demos/demo-infra-vm-02-vela-timoni/test-vm.yaml` (Demo 3)
  - `helm/demos/demo-infra-vm-03-vela-native/test-vm-native.yaml` (Demo 4)

- **Timoni Modules**:
  - `helm/timoni/modules/infra/vm/` (VM module source with deleteOption: Delete)
  - `oci://catalina.azurecr.io/vm-module:0.1.8` (Published module with disk deletion fix)

- **Documentation**:
  - `helm/vela/CUE_PATTERNS.md` (CUE templating patterns)
  - `helm/ROADMAP.md` (Project roadmap)
  - `helm/timoni/modules/infra/vm/README.md` (VM module docs)

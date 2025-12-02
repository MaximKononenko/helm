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

**Location**: `helm/demos/demo-infra-vm-02-timoni/`

### Architecture
```
Timoni CLI → ASO2 CRDs → Azure API → Virtual Machine
```

### Commands

```bash
# 1. Navigate to demo
cd helm/demos/demo-infra-vm-02-timoni

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

**Location**: `helm/demos/demo-infra-vm-03-vela-timoni/`

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
cd helm/demos/demo-infra-vm-03-vela-timoni

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

**Location**: `helm/demos/demo-infra-vm-04-vela-native/`

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
cd helm/demos/demo-infra-vm-04-vela-native

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

| Feature | Demo 1<br/>App + Timoni | Demo 2<br/>Infra + Timoni | Demo 3<br/>Infra + KubeVela + Timoni | Demo 4<br/>Infra + KubeVela Native | Demo 5<br/>REST API Integration | Demo 6<br/>Traits (Policies) | Demo 7<br/>Workflows | Demo 08<br/>Import |
|---------|-------------------------|---------------------------|--------------------------------------|-----------------------------------|----------------------------------|------------------------------|----------------------|---------------------|
| **Use Case** | Application deployment | Infrastructure testing | Orchestrated infra | Self-service platform | UI/API integration | Composable policies | Approval workflows | Brownfield migration |
| **Tool** | Timoni | Timoni | KubeVela + Timoni | KubeVela | Kubernetes REST API | KubeVela Traits | KubeVela Workflow | asoctl + ASO2 |
| **Execution** | CLI/ArgoCD | CLI | Job wrapper | Controller | HTTP/REST | Controller | Workflow Engine | CLI → Adoption |
| **Bundles** | ✅ bundle.cue | ✅ bundle.cue | ❌ N/A | ❌ N/A | ❌ N/A | ❌ N/A | ❌ N/A | ❌ N/A |
| **Create** | ✅ | ✅ | ✅ | ✅ | ✅ POST | ✅ | ⚠️ After approval | ✅ Adopt (no recreation) |
| **Update** | ✅ | ✅ | ⚠️ Manual | ✅ | ⚠️ PATCH (needs complete payload) | ✅ | ⚠️ After approval | ✅ After adoption |
| **Delete** | ✅ | ✅ | ⚠️ Manual | ✅ | ✅ DELETE | ✅ | ⚠️ After approval | ⚠️ Optional (detach-on-delete) |
| **OAM Abstraction** | ❌ | ❌ | ⚠️ Limited | ✅ | ✅ (via Application CRD) | ✅ | ✅ | ✅ (after conversion) |
| **Policy Enforcement** | ⚠️ Module-level | ⚠️ Module-level | ⚠️ Module-level | ✅ CUE validation | ✅ CUE validation + RBAC | ✅ Trait-based | ✅ Approval gates | ✅ Can add traits |
| **API Integration** | ❌ CLI only | ❌ CLI only | ⚠️ Job-based | ✅ REST API | ✅ Pure REST API | ✅ REST API | ✅ REST API | ⚠️ CLI then REST |
| **Authentication** | N/A | N/A | N/A | N/A | ✅ Bearer Token | ✅ Bearer Token | ✅ Bearer Token | ✅ Azure auth |
| **RBAC** | N/A | N/A | N/A | ⚠️ Admin-level | ✅ ServiceAccount-based | ✅ ServiceAccount-based | ✅ Role-based approvers | ✅ ASO credentials |
| **Traits Support** | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ Primary Feature | ✅ | ✅ After adoption |
| **Tag Composition** | ⚠️ Hardcoded | ⚠️ Hardcoded | ⚠️ Hardcoded | ✅ User + Platform | ✅ User + Platform | ✅ User + Platform + Traits | ✅ User + Platform + Traits | ✅ Preserves existing |
| **Separation of Concerns** | ❌ | ❌ | ❌ | ⚠️ Limited | ⚠️ Limited | ✅ Full | ✅ Full | ✅ Full (after conversion) |
| **Policy Composability** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Mix & Match | ✅ Mix & Match | ✅ Mix & Match |
| **UI-Ready** | ❌ | ❌ | ❌ | ⚠️ kubectl proxy | ✅ Direct HTTPS | ✅ Direct HTTPS | ✅ Direct HTTPS | ⚠️ Backend script |
| **Approval Required** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Primary Feature | ❌ |
| **Notification** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Email/Teams/Slack | ❌ |
| **Downtime Risk** | N/A | N/A | N/A | N/A | N/A | N/A | N/A | ✅ Zero downtime |
| **Terraform Migration** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Primary use case |
| **Complexity** | Low | Low | High | Medium | Medium | Medium | High | Low (automated) |
| **Best For** | Developers | Testing | ❌ Not recommended | Platform engineering | UI/Frontend integration | Enterprise governance | Regulated environments | Migration & Adoption |

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

## Demo 5: Infrastructure (VM) with REST API

**Use Case**: 🚀 **UI INTEGRATION** - REST API calls for platform self-service

**Location**: `helm/demos/demo-infra-vm-05-api/`

### Architecture
```
Your UI (React/Angular) → HTTPS REST API (Bearer Token)
    ↓
Kubernetes API Server
    ↓
KubeVela Application CRD
    ↓
ComponentDefinition (CUE template)
    ↓
ASO2 CRDs
    ↓
Azure Resources
```

### Prerequisites

```bash
# 1. Apply RBAC resources
kubectl apply -f helm/demos/demo-infra-vm-05-api/rbac.yaml

# 2. Create service account token (dynamic - 10 minute expiry)
TOKEN=$(kubectl create token platform-api-user \
  --namespace azureserviceoperator-system \
  --duration=10m)

# 3. Get API server endpoint
API_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

# 4. Test connectivity
curl -k -H "Authorization: Bearer ${TOKEN}" \
  "${API_SERVER}/apis/core.oam.dev/v1beta1/namespaces/azureserviceoperator-system/applications"
```

### RBAC Configuration

The `rbac.yaml` creates:

1. **ServiceAccount**: `platform-api-user`
   - Namespace: `azureserviceoperator-system`
   - Used for API authentication

2. **ClusterRole**: `platform-api-role`
   - Permissions:
     - KubeVela Applications: full CRUD
     - ComponentDefinitions: read-only
     - ASO2 resources: read-only (verification)
     - ConfigMaps: read-only (workflow context)

3. **ClusterRoleBinding**: Links ServiceAccount → ClusterRole

4. **Secret**: `platform-api-token` (optional)
   - Long-lived token for non-expiring access
   - Alternative to dynamic token generation

### Commands

```bash
# 1. Navigate to demo
cd helm/demos/demo-infra-vm-05-api

# 2. Review API payloads
cat vm-create.json   # POST payload
cat vm-update.json   # PATCH payload

# 3. Run automated test
./test-api.sh

# 4. Or run manual REST API calls:

# CREATE: POST new Application
curl -k -X POST \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d @vm-create.json \
  "${API_SERVER}/apis/core.oam.dev/v1beta1/namespaces/azureserviceoperator-system/applications"

# READ: GET Application status
curl -k -H "Authorization: Bearer ${TOKEN}" \
  "${API_SERVER}/apis/core.oam.dev/v1beta1/namespaces/azureserviceoperator-system/applications/vm-api-test"

# UPDATE: PATCH Application (resize VM)
curl -k -X PATCH \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/merge-patch+json" \
  -d @vm-update.json \
  "${API_SERVER}/apis/core.oam.dev/v1beta1/namespaces/azureserviceoperator-system/applications/vm-api-test"

# DELETE: Remove Application
curl -k -X DELETE \
  -H "Authorization: Bearer ${TOKEN}" \
  "${API_SERVER}/apis/core.oam.dev/v1beta1/namespaces/azureserviceoperator-system/applications/vm-api-test"

# 5. Verify in Azure
az vm show \
  --resource-group rg-tst-eastus-istio-compute \
  --name vm-api-test-01 \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c \
  --query '{name:name, state:provisioningState, size:hardwareProfile.vmSize, tags:tags}' \
  -o table
```

### Test Results

**✅ Successful Operations:**
- CREATE: Application created, VM provisioned (Standard_B1s for dev/small)
- READ: Status retrieved with health and phase information
- DELETE: Complete cleanup including disk deletion
- Tags: User tags merged with platform defaults

**⚠️ Known Issues:**
- UPDATE/PATCH: Requires complete Application properties, not just changed fields
  - Current `vm-update.json` only includes `vmSize` → workflow fails validation
  - DELETE still works after failed update (graceful degradation)
  - Solution: Include all required properties in PATCH payload

**🎯 Validation:**
- No orphaned disks after deletion
- Service account authentication working
- Bearer token authorization successful
- Full CRUD lifecycle via REST API proven

### Key Features
- ✅ Pure REST API (no CLI dependencies)
- ✅ Standard Kubernetes API endpoints
- ✅ Bearer token authentication
- ✅ JSON payloads (POST/PATCH)
- ✅ Full CUD lifecycle support
- ✅ Ready for UI integration (React/Angular)
- ✅ RBAC-controlled access
- ✅ Dynamic or long-lived tokens

### API Payload Examples

**Create VM (vm-create.json)**:
```json
{
  "apiVersion": "core.oam.dev/v1beta1",
  "kind": "Application",
  "metadata": {"name": "vm-api-test"},
  "spec": {
    "components": [{
      "name": "vm",
      "type": "azure-vm",
      "properties": {
        "vmName": "vm-api-test-01",
        "vmSize": "small",
        "environment": "dev",
        "resourceGroup": "rg-tst-eastus-istio-compute",
        "network": {...},
        "tags": {
          "Owner": "api-test",
          "Project": "api-demo",
          "CreatedVia": "REST-API"
        }
      }
    }]
  }
}
```

**Update VM (vm-update.json)** - ⚠️ Needs improvement:
```json
{
  "spec": {
    "components": [{
      "properties": {
        "vmSize": "large"
      }
    }]
  }
}
```

### Critical Discoveries

**1. Tag Naming Conflicts** - User tags can conflict with CUE computed fields:
```yaml
# ❌ Causes CUE error: "2 errors in empty disjunction"
tags: {
  Environment: "prod"  # Conflicts with _computedTags.Environment
}

# ✅ Use different field names
tags: {
  Project: "api-demo",
  Owner: "api-test"
}
```

**2. PATCH Payload Completeness** - Merge-patch requires all properties:
```json
// ❌ Incomplete (causes workflow validation failure)
{"spec": {"components": [{"properties": {"vmSize": "large"}}]}}

// ✅ Complete (should include all required fields)
{
  "spec": {
    "components": [{
      "name": "vm",
      "type": "azure-vm",
      "properties": {
        "vmName": "vm-api-test-01",
        "vmSize": "large",
        "environment": "dev",
        "resourceGroup": "...",
        "network": {...},
        "tags": {...}
      }
    }]
  }
}
```

**3. Service Account Tokens**:
- Dynamic tokens: `kubectl create token` with `--duration` flag
- Long-lived tokens: Create Secret with `kubernetes.io/service-account-token` type
- Recommendation: Use dynamic tokens with reasonable expiry (1-4 hours) for security

---

## Demo 6: Infrastructure Traits (Policies)

**Use Case**: 🎯 **COMPOSABLE POLICIES** - Add cross-cutting concerns without modifying ComponentDefinitions

**Location**: `helm/demos/demo-infra-vm-06-traits/`

### Architecture
```
User Application
    ↓
Component (azure-vm)
    ↓
Traits (backup-policy + cost-tracking + security-baseline + monitoring)
    ↓
ComponentDefinition (CUE template with patches)
    ↓
ASO2 CRDs with merged tags + ConfigMaps
    ↓
Azure Resources
```

### What are Traits?

**Traits** are reusable operational behaviors attached to workloads:
- **Separation of Concerns**: Infrastructure logic vs operational policies
- **Policy Enforcement**: Organization-wide standards
- **Composability**: Mix and match as needed
- **Reusability**: Define once, apply everywhere

### Available Traits

1. **backup-policy**: Backup configuration and vault assignment
2. **cost-tracking**: Cost allocation and chargeback tags
3. **security-baseline**: Security and compliance settings
4. **monitoring**: Alerting and metrics configuration

### Prerequisites

```bash
# 1. Navigate to definitions
cd helm/vela/definitions

# 2. Apply TraitDefinitions
kubectl apply -f backup-policy-trait.yaml
kubectl apply -f cost-tracking-trait.yaml
kubectl apply -f security-baseline-trait.yaml
kubectl apply -f monitoring-trait.yaml

# 3. Verify traits are available
kubectl get traitdefinition -n vela-system
```

### Demo 1: Full Traits Stack (Production VM)

```bash
# 1. Navigate to demo
cd helm/demos/demo-infra-vm-06-traits

# 2. Review Application with all traits
cat vm-with-all-traits.yaml

# 3. Create VM with all traits
kubectl apply -f vm-with-all-traits.yaml

# 4. Monitor Application
kubectl get application.core.oam.dev vm-with-traits -n azureserviceoperator-system
kubectl describe application.core.oam.dev vm-with-traits -n azureserviceoperator-system

# 5. Check trait outputs (ConfigMaps)
kubectl get configmap -n azureserviceoperator-system | grep vm-with-traits

# View backup configuration
kubectl get configmap vm-with-traits-backup-config -n azureserviceoperator-system -o yaml

# View security configuration
kubectl get configmap vm-with-traits-security-config -n azureserviceoperator-system -o yaml

# View alert configuration
kubectl get configmap vm-with-traits-alert-config -n azureserviceoperator-system -o yaml

# 6. Verify tags in Azure
az vm show \
  --resource-group rg-tst-eastus-istio-compute \
  --name vm-traits-demo-01 \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c \
  --query '{name:name, size:hardwareProfile.vmSize, tags:tags}' \
  -o json | jq .tags

# Expected tags from traits:
# Backup: BackupEnabled, BackupRetention, BackupSchedule, BackupVault
# Cost: CostCenter, Department, Project, BillingCode, Approver
# Security: SecurityLevel, ComplianceFramework, DataClassification, PatchingSchedule
# Monitoring: MonitoringEnabled, AlertSeverity, AlertContact, MetricsRetention, MonitoringStack, DatadogEnv
# Plus user tags: Owner, Purpose
# Plus platform tags: ManagedBy, Environment

# 7. Cleanup
kubectl delete application.core.oam.dev vm-with-traits -n azureserviceoperator-system
```

### Demo 2: Minimal Traits (Developer Use Case)

```bash
# 1. Review minimal configuration
cat vm-with-minimal-traits.yaml

# 2. Create VM with cost tracking only
kubectl apply -f vm-with-minimal-traits.yaml

# 3. Monitor
kubectl get application.core.oam.dev vm-minimal-traits -n azureserviceoperator-system

# 4. Verify only cost tracking tags in Azure
az vm show \
  --resource-group rg-tst-eastus-istio-compute \
  --name vm-traits-minimal-01 \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c \
  --query 'tags' -o json

# 5. Cleanup
kubectl delete application.core.oam.dev vm-minimal-traits -n azureserviceoperator-system
```

### Demo 3: Data Disks with Trait Inheritance

```bash
# 1. Review configuration with data disks
cat vm-with-data-disks.yaml

# 2. Create VM with data disks
kubectl apply -f vm-with-data-disks.yaml

# 3. Monitor
kubectl get application.core.oam.dev vm-with-disks -n azureserviceoperator-system

# 4. Check Disk resources (created as separate ASO2 resources)
kubectl get disks.compute.azure.com -n azureserviceoperator-system

# 5. Verify VM and data disks in Azure
az vm show \
  --resource-group rg-tst-eastus-istio-compute \
  --name vm-disks-demo-01 \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c \
  --query '{name:name, size:hardwareProfile.vmSize, dataDisks:storageProfile.dataDisks[].{name:name,sizeGB:diskSizeGb,caching:caching,storageType:managedDisk.storageAccountType}}' \
  -o json

# 6. Verify tag inheritance on data disks
az disk show \
  --resource-group rg-tst-eastus-istio-compute \
  --name vm-disks-demo-01-datadisk-0 \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c \
  --query '{name:name, sizeGB:diskSizeGb, tags:tags}' -o json

# Expected: Data disk has User + Platform tags (no trait tags, traits apply to VM only)

# 7. Cleanup
kubectl delete application.core.oam.dev vm-with-disks -n azureserviceoperator-system
```

**Key Features:**
- Data disks created as separate `Disk` resources (ASO2)
- Automatic attachment via `createOption: "Attach"`
- Tag inheritance: Data disks get User + Platform tags
- Different caching modes per disk (ReadWrite, None)
- Automatic cleanup with `deleteOption: "Delete"`

### Trait Details

**1. backup-policy**
```yaml
traits:
  - type: backup-policy
    properties:
      enabled: "true"
      retentionDays: 30
      schedule: "0 2 * * *"  # Daily at 2 AM
      vaultName: "backup-vault-eastus"
```
- Adds backup tags to VM
- Creates ConfigMap with backup configuration
- Integrates with Azure Backup service

**2. cost-tracking** (Required for all VMs)
```yaml
traits:
  - type: cost-tracking
    properties:
      costCenter: "ENG-001"
      department: "Engineering"
      project: "platform-poc"
      approver: "engineering-lead@company.com"
```
- Adds cost allocation tags
- Enables Azure Cost Management queries
- Supports chargeback/showback reporting

**3. security-baseline**
```yaml
traits:
  - type: security-baseline
    properties:
      securityLevel: "internal"  # public/internal/confidential/restricted
      complianceFramework: "sox"  # none/pci-dss/hipaa/sox/gdpr
      dataClassification: "confidential"
      patchingSchedule: "weekly"  # immediate/weekly/monthly
```
- Adds security and compliance tags
- Creates ConfigMap for security scanning
- Enables compliance reporting

**4. monitoring**
```yaml
traits:
  - type: monitoring
    properties:
      enabled: true
      alertSeverity: "high"  # critical/high/medium/low
      alertContact: "ops-team@company.com"
      metricsRetentionDays: 90
      monitoringStack: "both"  # datadog/prometheus/both
      datadogEnv: "production"
      cpuThreshold: 85
      memoryThreshold: 90
      diskThreshold: 80
```
- Adds monitoring tags
- Creates ConfigMap with alert thresholds
- Integrates with Datadog APM and Prometheus/Grafana stack

### Key Benefits

**1. Separation of Concerns**
- Developers: Focus on VM specs (size, network, storage)
- Platform Team: Enforce policies via traits
- Security Team: Define compliance requirements
- Finance Team: Control cost allocation

**2. Composability**
```yaml
# Production: All policies
traits:
  - backup-policy: {retentionDays: 90}
  - cost-tracking: {costCenter: "PROD-001"}
  - security-baseline: {securityLevel: "restricted"}
  - monitoring: {alertSeverity: "critical"}

# Development: Minimal policies
traits:
  - cost-tracking: {costCenter: "DEV-002"}
```

**3. Policy Enforcement**
- Admission webhooks can require traits
- Validate trait parameters
- Prevent non-compliant deployments

**4. Audit and Compliance**
```bash
# Audit: Which VMs have backup enabled?
kubectl get application -n azureserviceoperator-system -o json | \
  jq '.items[] | select(.spec.components[].traits[]? | .type == "backup-policy")'

# Compliance: List all SOX-compliant VMs
az resource list --tag ComplianceFramework=sox -o table
```

### Use Cases

**Platform Self-Service Portal**
```
┌─────────────────────────────────────┐
│ Create Virtual Machine              │
├─────────────────────────────────────┤
│ Name: [vm-user-123            ]     │
│ Size: [Standard_B2s ▼]              │
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

---

## Demo 7: Approval Workflows

**Use Case**: 🎯 **GOVERNANCE** - Multi-stage approval for infrastructure changes

**Location**: `helm/demos/demo-infra-vm-07-workflows/`

**Documentation**: See [Demo 07 README](demos/demo-infra-vm-07-workflows/README.md) for detailed discussion on:
- Approver management strategies (ConfigMap vs LDAP vs external service)
- Notification integrations (Slack, Microsoft Teams, Email)
- Multi-stage approval logic (sequential vs parallel)
- Policy validation with OPA
- Integration with TargetProcess ticketing system
- Monitoring and audit with Datadog + Grafana

### Architecture
```
User Request → Validation → Approval Workflow → Provisioning
                    ↓              ↓
            OPA Policy Check   Approver Notification
                    ↓          (Slack/Teams)
              Auto/Manual          ↓
               Approval      Approve/Reject Decision
                    ↓              ↓
            Provision or Cancel (Audit to Datadog)
```

### Key Features
- **Multi-stage approvals**: Sequential approval chains (team lead → finance → security)
- **Conditional workflows**: Approval requirements based on resource cost/type
- **Notification integration**: Slack and Microsoft Teams webhooks
- **OPA policy validation**: Auto-approve compliant requests, block violations
- **Audit trail**: Complete approval history to Datadog + Grafana dashboards
- **Timeout handling**: Auto-reject or escalate after timeout
- **TargetProcess integration**: Link approvals to tickets
- **Self-service with governance**: Users request, approvers control

**Status**: 🔜 Design phase - Review README for discussion topics

---

## Demo 08: Importing Existing VMs (Brownfield Migration)

**Use Case**: 🎯 **ADOPT WITHOUT RECREATION** - Import existing VMs into KubeVela management

**Location**: `helm/demos/demo-infra-vm-08-import/`

**Documentation**: See [Demo 08 README](demos/demo-infra-vm-08-import/README.md) for substeps:
- **08.1**: Basic single VM import with `asoctl`
- **08.2**: Import with dependencies (NICs, Disks, NSGs)
- **08.3**: Wrap in KubeVela Application
- **08.4**: Apply traits to imported VMs
- **08.5**: Bulk import automation
- **08.6**: Migration from Terraform
- **08.7**: Configuration drift detection
- **08.8**: Import templates and documentation

### Architecture
```
Existing Azure VM
    ↓
asoctl import (generate YAML)
    ↓
ASO2 CRDs (adopt existing resource)
    ↓
No recreation - immediate management
    ↓
Optional: Convert to ComponentDefinition
```

### What is Adoption?

**Adoption** lets ASO2 manage existing Azure resources without recreation:
- **No Downtime**: Resources stay running during import
- **No Data Loss**: Existing disks, configurations preserved
- **Similar to Terraform Import**: But with automatic configuration generation
- **Detach-on-Delete**: Optional protection against accidental deletion

### Prerequisites

```bash
# 1. Install asoctl CLI
curl -L https://github.com/Azure/azure-service-operator/releases/latest/download/asoctl-linux-amd64.gz -o /tmp/asoctl.gz
gunzip /tmp/asoctl.gz
sudo install -o root -g root -m 0755 /tmp/asoctl /usr/local/bin/asoctl

# 2. Verify installation
asoctl version

# 3. Ensure Azure CLI is authenticated
az account show
```

### Import Workflow

#### Step 1: Import Existing VM

```bash
# Navigate to demo
cd helm/demos/demo-infra-vm-07-import

# Option A: Use automated script
./import-existing-vm.sh

# Option B: Manual import
export RESOURCE_GROUP="rg-existing-vms"
export VM_NAME="existing-vm-01"

# Get VM ARM ID
VM_ARM_ID=$(az vm show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --query id -o tsv)

# Import configuration
asoctl import azure-resource "$VM_ARM_ID" \
  --output "imported-${VM_NAME}.yaml" \
  --namespace azureserviceoperator-system \
  --annotation "serviceoperator.azure.com/reconcile-policy=detach-on-delete" \
  --label "managed-by=kubevela" \
  --verbose
```

**What gets imported:**
- ✅ VirtualMachine resource
- ✅ NetworkInterface
- ✅ OS Disk
- ✅ Data Disks (if any)
- ✅ All current tags
- ✅ Complete configuration

#### Step 2: Apply to Kubernetes

```bash
# Apply imported resources
kubectl apply -f imported-existing-vm-01.yaml

# Verify adoption (no Azure changes)
kubectl get virtualmachine.compute.azure.com existing-vm-01 -n azureserviceoperator-system

# Check status - should show "Ready" immediately
kubectl describe virtualmachine.compute.azure.com existing-vm-01 -n azureserviceoperator-system
```

**Key Point**: ASO adopts the existing VM by matching name and ARM ID. No recreation occurs.

#### Step 3: Convert to ComponentDefinition (Optional)

```bash
# Use conversion script
./convert-to-definition.sh imported-existing-vm-01.yaml

# This generates vm-with-definition.yaml using azure-vm ComponentDefinition

# Delete old raw resources
kubectl delete -f imported-existing-vm-01.yaml

# Apply new Application (ASO will adopt, not recreate)
kubectl apply -f vm-with-definition.yaml
```

### Reconcile Policy Options

**Default (Manage + Delete)**:
```yaml
# No annotation needed
metadata:
  name: my-vm
```
- ASO manages the VM
- Deleting the CR **deletes the Azure VM**

**Detach-on-Delete (Manage Only)**:
```yaml
metadata:
  annotations:
    serviceoperator.azure.com/reconcile-policy: detach-on-delete
```
- ASO manages the VM
- Deleting the CR **leaves Azure VM intact**
- Good for testing or gradual migration

### Migration Scenarios

#### Scenario 1: Terraform → KubeVela

```bash
# 1. Identify Terraform-managed VMs
terraform state list | grep azurerm_virtual_machine

# 2. Import to ASO
for vm in $(terraform state list | grep azurerm_virtual_machine); do
  VM_NAME=$(terraform state show "$vm" | grep "name =" | head -1 | awk '{print $3}' | tr -d '"')
  # ... import logic
done

# 3. Remove from Terraform state
terraform state rm azurerm_virtual_machine.my_vm

# 4. Continue managing via KubeVela
```

#### Scenario 2: Portal-Created → Platform-Managed

```bash
# 1. List manually created VMs
az vm list --resource-group rg-manual --query "[].name" -o tsv

# 2. Bulk import
az vm list --resource-group rg-manual --query "[].id" -o tsv | \
  xargs -I {} asoctl import azure-resource {} \
    --output-folder ./imported/ \
    --namespace azureserviceoperator-system

# 3. Apply all
kubectl apply -f ./imported/

# 4. Add traits for compliance
for app in $(kubectl get application -n azureserviceoperator-system -o name); do
  kubectl patch "$app" --type=merge -p '{"spec":{"components":[{"traits":[{"type":"cost-tracking"}]}]}}'
done
```

#### Scenario 3: Gradual Migration with Protection

```bash
# Import with detach-on-delete for safety
asoctl import azure-resource "$VM_ARM_ID" \
  --annotation "serviceoperator.azure.com/reconcile-policy=detach-on-delete"

# Test management (tags, updates)
kubectl patch virtualmachine.compute.azure.com my-vm -p '{"spec":{"tags":{"Test":"true"}}}'

# Verify in Azure
az vm show --name my-vm --query tags

# Once confident, remove protection
kubectl annotate virtualmachine.compute.azure.com my-vm \
  serviceoperator.azure.com/reconcile-policy-
```

### Verification

```bash
# Check adoption status
kubectl get virtualmachine.compute.azure.com -n azureserviceoperator-system

# Expected: Ready=True, no provisioning changes in Azure
az vm show --resource-group rg-existing --name existing-vm-01 \
  --query provisioningState -o tsv
# Output: Succeeded (unchanged)

# Test management
kubectl patch virtualmachine.compute.azure.com existing-vm-01 \
  -n azureserviceoperator-system \
  --type=merge \
  -p '{"spec":{"tags":{"ManagedBy":"kubevela"}}}'

# Verify tag sync to Azure
az vm show --resource-group rg-existing --name existing-vm-01 \
  --query "tags.ManagedBy" -o tsv
# Output: kubevela
```

### Key Benefits

1. **Zero Downtime**: VMs stay running during adoption
2. **Automatic Config**: No manual YAML writing required
3. **Complete Import**: Child resources (disks, NICs) included
4. **Safe Testing**: detach-on-delete prevents accidental deletion
5. **Trait Integration**: Can add policies after adoption
6. **GitOps Ready**: Import once, manage forever via Git

### Comparison: Terraform Import vs ASO Adoption

| Feature | Terraform Import | ASO Adoption |
|---------|------------------|--------------|
| **Configuration Generation** | Manual (write HCL) | Automatic (asoctl) |
| **Recreation Risk** | High (config mismatch) | None (matches by ARM ID) |
| **Child Resources** | One-by-one import | Auto-discovered |
| **State Management** | Separate backend | Kubernetes etcd |
| **Drift Detection** | terraform plan | ASO reconciliation |
| **GitOps Integration** | Requires atlantis/similar | Native Kubernetes |
| **Rollback** | terraform state manipulation | kubectl rollout undo |

### Common Issues

**Issue**: `Failed to adopt - resource already exists`
```bash
# Solution: Delete conflicting Kubernetes resource first
kubectl delete virtualmachine.compute.azure.com conflicting-vm -n azureserviceoperator-system
```

**Issue**: `Import succeeds but Ready=False`
```bash
# Check conditions
kubectl describe virtualmachine.compute.azure.com my-vm -n azureserviceoperator-system

# Common causes:
# - Invalid credential reference
# - Missing ASO permissions
# - Network/subnet not found
```

**Issue**: `Accidental deletion of Azure resource`
```bash
# Prevention: Always use detach-on-delete during testing
metadata:
  annotations:
    serviceoperator.azure.com/reconcile-policy: detach-on-delete
```

---

## Next Steps

1. ✅ **Demo 4 Complete**: Full CUD lifecycle validated via REST API
2. ✅ **Demo 5 Complete**: REST API integration with ServiceAccount RBAC
3. ✅ **Demo 6 Complete**: Traits validated (Backup, Cost, Security, Monitoring) + Data disks
4. ✅ **Import Workflow**: ASO2 adoption without recreation documented (Demo XX)
5. ✅ **ASO2 CRDs**: Organized under `helm/aso2/` with live management
6. 🔜 **Demo 7 Focus**: Approval Workflows - Design and implementation
   - Multi-stage approval chains
   - Notification integration (Email/Teams/Slack)
   - Role-based approvers
   - Audit trail and compliance
7. **Bulk Migration**: Import production Terraform-managed infrastructure
8. **Create UI Mockups**: Show how users interact with the platform
9. **Policy Enforcement**: Admission webhook to require traits
10. **Enhanced RBAC**: Namespace-scoped roles for tenant isolation
11. **Cost Estimation**: Pre-deployment cost calculation based on vmSize + traits

---

## Files Reference

- **ComponentDefinitions**:
  - `helm/vela/definitions/timoni-module.yaml` (Job wrapper - Demo 3)
  - `helm/vela/definitions/azure-vm.yaml` (Native ASO2 - Demo 4)
  - `helm/vela/definitions/rbac.yaml` (ServiceAccount and permissions)

- **Applications**:
  - `helm/demos/demo-infra-vm-03-vela-timoni/test-vm.yaml` (Demo 3)
  - `helm/demos/demo-infra-vm-04-vela-native/test-vm-native.yaml` (Demo 4)
  - `helm/demos/demo-infra-vm-05-api/vm-create.json` (Demo 5 - POST)
  - `helm/demos/demo-infra-vm-05-api/vm-update.json` (Demo 5 - PATCH)
  - `helm/demos/demo-infra-vm-06-traits/vm-with-all-traits.yaml` (Demo 6 - Full traits)
  - `helm/demos/demo-infra-vm-06-traits/vm-with-minimal-traits.yaml` (Demo 6 - Minimal)
  - `helm/demos/demo-infra-vm-06-traits/vm-with-data-disks.yaml` (Demo 6 - Data disks)

- **RBAC**:
  - `helm/demos/demo-infra-vm-05-api/rbac.yaml` (ServiceAccount, ClusterRole, ClusterRoleBinding, Token Secret)

- **Traits (Policies)**:
  - `helm/vela/definitions/backup-policy-trait.yaml` (Backup configuration)
  - `helm/vela/definitions/cost-tracking-trait.yaml` (Cost allocation tags)
  - `helm/vela/definitions/security-baseline-trait.yaml` (Security and compliance)
  - `helm/vela/definitions/monitoring-trait.yaml` (Alerting and metrics with Datadog/Prometheus)

- **Approval Workflows (Demo 7)**:
  - `helm/demos/demo-infra-vm-07-workflows/README.md` (Design discussion and options)
  - Workflow definitions with approval steps (TBD)
  - Notification webhooks for Slack and Microsoft Teams (TBD)
  - OPA policy validation (TBD)
  - RBAC for approvers (TBD)
  - Audit trail to Datadog + Grafana (TBD)
  - TargetProcess integration (TBD)

- **Import/Migration (Demo 08)**:
  - `helm/demos/demo-infra-vm-08-import/README.md` (8 substeps from basic to advanced)
  - `helm/demos/demo-infra-vm-08-import/import-existing-vm.sh` (Automated import script)
  - `helm/demos/demo-infra-vm-08-import/convert-to-definition.sh` (Convert to ComponentDefinition)

- **ASO2 CRDs**:
  - `helm/aso2/azureserviceoperator_customresourcedefinitions_v2.16.0.yaml` (Complete CRD bundle)
  - `helm/aso2/live/vm-crds.yaml` (VirtualMachine, NetworkInterface)
  - `helm/aso2/live/aks-crds.yaml` (ManagedCluster and related resources)
  - `helm/aso2/live/disk-crd.yaml` (Disk for data disk management)

- **Automation**:
  - `helm/demos/demo-infra-vm-05-api/test-api.sh` (Full REST API test script)
  - `helm/demos/demo-infra-vm-05-api/README.md` (API documentation with JavaScript examples)
  - `helm/demos/demo-infra-vm-06-traits/README.md` (Traits documentation and use cases)
  - `helm/demos/demo-infra-vm-06-traits/test-traits.sh` (Traits testing script)

- **Timoni Modules**:
  - `helm/timoni/modules/infra/vm/` (VM module source with deleteOption: Delete)
  - `oci://catalina.azurecr.io/vm-module:0.1.8` (Published module with disk deletion fix)

- **Documentation**:
  - `helm/vela/CUE_PATTERNS.md` (CUE templating patterns)
  - `helm/ROADMAP.md` (Project roadmap)
  - `helm/timoni/modules/infra/vm/README.md` (VM module docs)

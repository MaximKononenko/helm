# Demo 4: REST API Integration

This demo showcases how your UI/Portal would interact with the KubeVela platform using standard Kubernetes REST APIs.

## Files

- `vm-create.json` - Application manifest for CREATE operation
- `vm-update.json` - Patch payload for UPDATE operation  
- `test-api.sh` - Automated test script demonstrating full CUD lifecycle

## Architecture

```
Your UI (JavaScript/Python)
    ↓ HTTP REST API
Kubernetes API Server
    ↓ KubeVela Controller
ASO2 CRDs
    ↓ Azure Resource Manager
Virtual Machine (Azure)
```

## API Operations

### 1. CREATE - Provision VM

```bash
POST https://k8s-api/apis/core.oam.dev/v1beta1/namespaces/azureserviceoperator-system/applications
Content-Type: application/json
Authorization: Bearer <token>

{
  "apiVersion": "core.oam.dev/v1beta1",
  "kind": "Application",
  "metadata": {
    "name": "vm-api-test",
    "namespace": "azureserviceoperator-system"
  },
  "spec": {
    "components": [{
      "name": "my-vm",
      "type": "azure-vm",
      "properties": {
        "vmSize": "small",
        "environment": "dev",
        ...
      }
    }]
  }
}
```

**Response**: Application created (201 Created)

### 2. READ - Get Status

```bash
GET https://k8s-api/apis/core.oam.dev/v1beta1/namespaces/azureserviceoperator-system/applications/vm-api-test
Authorization: Bearer <token>
```

**Response**: Application status with workflow phase, health, and resource details

### 3. UPDATE - Resize VM

```bash
PATCH https://k8s-api/apis/core.oam.dev/v1beta1/namespaces/azureserviceoperator-system/applications/vm-api-test
Content-Type: application/merge-patch+json
Authorization: Bearer <token>

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

**Response**: Application updated (200 OK), KubeVela triggers Azure resize

### 4. DELETE - Cleanup

```bash
DELETE https://k8s-api/apis/core.oam.dev/v1beta1/namespaces/azureserviceoperator-system/applications/vm-api-test
Authorization: Bearer <token>
```

**Response**: Application deleted (200 OK), ASO2 cleans up Azure resources

## Running the Demo

### Prerequisites

1. kubectl configured with access to management cluster
2. Azure CLI logged in (`az login`)
3. jq installed for JSON parsing

### Execute

```bash
cd /home/mkononen/pet-projects/helm/demos/demo-infra-vm-04-api
./test-api.sh
```

### Expected Flow

1. ✅ POST creates Application → VM provisions in Azure (Standard_B1s - dev/small)
2. ✅ GET shows Application status (healthy, running)
3. ✅ Azure verification shows VM running with correct tags
4. ✅ PATCH updates vmSize → Azure resizes VM to Standard_D2s_v3 (dev/large)
5. ✅ Azure verification shows updated VM size
6. ✅ DELETE removes Application → ASO2 deletes VM and disk
7. ✅ Azure verification confirms cleanup (ResourceNotFound)

## Authentication

The script uses token from kubeconfig. In production, your UI would use:

**Option 1: Service Account Token (Recommended)**
```bash
kubectl create serviceaccount platform-ui -n azureserviceoperator-system
kubectl create clusterrolebinding platform-ui --clusterrole=application-admin --serviceaccount=azureserviceoperator-system:platform-ui
TOKEN=$(kubectl create token platform-ui -n azureserviceoperator-system)
```

**Option 2: OIDC Integration**
- Azure AD authentication
- User permissions mapped to Kubernetes RBAC
- Token obtained via OAuth2 flow

## Error Handling

**Common HTTP Status Codes:**
- `201 Created` - Resource created successfully
- `200 OK` - Operation successful
- `404 Not Found` - Application doesn't exist
- `409 Conflict` - Application already exists (CREATE)
- `422 Unprocessable Entity` - Validation error (check properties)
- `403 Forbidden` - Insufficient RBAC permissions

**Example Error Response:**
```json
{
  "kind": "Status",
  "apiVersion": "v1",
  "status": "Failure",
  "message": "applications.core.oam.dev \"vm-api-test\" already exists",
  "reason": "AlreadyExists",
  "code": 409
}
```

## UI Integration Example (JavaScript)

```javascript
class PlatformAPI {
  constructor(apiServer, token) {
    this.apiServer = apiServer;
    this.token = token;
  }

  async createVM(name, size, environment, tags) {
    const response = await fetch(
      `${this.apiServer}/apis/core.oam.dev/v1beta1/namespaces/azureserviceoperator-system/applications`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          apiVersion: 'core.oam.dev/v1beta1',
          kind: 'Application',
          metadata: { name, namespace: 'azureserviceoperator-system' },
          spec: {
            components: [{
              name: 'my-vm',
              type: 'azure-vm',
              properties: {
                vmName: name,
                vmSize: size,
                environment: environment,
                resourceGroup: 'rg-tst-eastus-istio-compute',
                network: { /* ... */ },
                tags: tags
              }
            }]
          }
        })
      }
    );
    return response.json();
  }

  async getVMStatus(name) {
    const response = await fetch(
      `${this.apiServer}/apis/core.oam.dev/v1beta1/namespaces/azureserviceoperator-system/applications/${name}`,
      {
        headers: { 'Authorization': `Bearer ${this.token}` }
      }
    );
    return response.json();
  }

  async resizeVM(name, newSize) {
    const response = await fetch(
      `${this.apiServer}/apis/core.oam.dev/v1beta1/namespaces/azureserviceoperator-system/applications/${name}`,
      {
        method: 'PATCH',
        headers: {
          'Authorization': `Bearer ${this.token}`,
          'Content-Type': 'application/merge-patch+json'
        },
        body: JSON.stringify({
          spec: {
            components: [{
              properties: { vmSize: newSize }
            }]
          }
        })
      }
    );
    return response.json();
  }

  async deleteVM(name) {
    const response = await fetch(
      `${this.apiServer}/apis/core.oam.dev/v1beta1/namespaces/azureserviceoperator-system/applications/${name}`,
      {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${this.token}` }
      }
    );
    return response.json();
  }
}

// Usage
const api = new PlatformAPI('https://k8s-api', userToken);

// User clicks "Create VM" button
await api.createVM('user-vm-123', 'medium', 'dev', {
  Owner: 'john.doe',
  CostCenter: 'engineering'
});

// User clicks "Upgrade" button
await api.resizeVM('user-vm-123', 'large');

// Poll for status
const status = await api.getVMStatus('user-vm-123');
console.log('VM Status:', status.status.workflow.phase);
```

## Benefits Over CLI/Pipeline Approach

✅ **Real-time**: Immediate feedback via API
✅ **Stateless**: No terraform state files
✅ **RBAC**: Native Kubernetes permissions
✅ **Auditable**: All operations logged in K8s audit
✅ **Declarative**: Desired state in Application CR
✅ **Self-healing**: KubeVela reconciles drift
✅ **Policy-driven**: Traits enforce governance

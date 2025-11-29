# K8s-Ops-Box GitOps Test Repository

This repository contains sample k8s-ops-box Custom Resources for testing GitOps functionality, along with infrastructure provisioning patterns using KubeVela, Timoni, and Azure Service Operator (ASO2).

## Architecture Overview

### Infrastructure Provisioning Stack

```
KubeVela Application (applications/*.yaml)
  └─> uses ComponentDefinition (definitions/timoni-module.yaml)
      └─> renders Timoni module with values
          └─> produces ASO2 Custom Resources (VirtualMachine, NetworkInterface, etc.)
              └─> ASO2 Operator watches these CRs
                  └─> calls Azure ARM API to provision actual infrastructure
```

**What Each Tool Does:**
- **Timoni** - Templating/packaging tool using CUE (replaces Helm charts)
  - Vendors CRDs for type safety and validation
  - Templates ASO2 Custom Resources
  - Provides strong typing and composition capabilities
- **KubeVela** - Workflow orchestrator and application delivery platform
  - Applies manifests rendered by Timoni
  - Provides workflow capabilities (multi-step, approval gates, etc.)
  - Manages application lifecycle
- **ASO2** - Infrastructure controller (Azure Service Operator v2)
  - Watches for ASO2 CRs in the cluster
  - Provisions actual Azure resources via ARM API
  - Updates CR status with provisioning progress

## Structure

```
.
├── clusters/              # RemoteCluster CRs
│   ├── dev-cluster.yaml
│   └── staging-cluster.yaml
├── roles/                 # OpsBoxRole CRs
│   ├── developer-role.yaml
│   └── viewer-role.yaml
├── subjects/              # OpsBoxSubject CRs
│   └── team-group.yaml
├── rbac-definitions/      # RBACDefinition CRs (with targetCluster)
│   ├── dev-rbac.yaml
│   ├── minikube-local-rbac.yaml
│   └── staging-rbac.yaml
├── cron-definitions/      # CronDefinition CRs (with targetCluster)
│   ├── minikube-backup.yaml
│   └── python-health-check.yaml
├── git-definitions/       # GitDefinition CRs
│   ├── demo-app-source.yaml
│   ├── test-ado-gitops.yaml
│   └── test-gitops-local.yaml
├── projects-examples/     # Example projects with Helm charts
│   ├── demo-app-01/       # Demo app with umbrella chart structure
│   │   └── helm/          # Helm chart with frontend and backend subcharts
│   └── demo-app-02/       # Another demo app (placeholder)
├── timoni/                # Timoni modules for infrastructure provisioning
│   └── modules/
│       └── infra/
│           ├── aks/       # AKS cluster module (Greenfield)
│           └── vm/        # VM module (Brownfield - using existing network)
└── vela/                  # KubeVela configuration
    ├── applications/      # KubeVela Applications (what to deploy)
    │   ├── aks-cluster.yaml    # AKS cluster application
    │   └── test-vm.yaml        # VM test application
    ├── definitions/       # ComponentDefinitions (how to deploy)
    │   ├── timoni-module.yaml  # Timoni module component type
    │   └── rbac.yaml           # RBAC component (for cluster setup)
    └── *.yaml             # CRD files and ASO2 operator manifests
```

### vela/ Folder Structure

The `vela/` folder contains KubeVela-specific configuration:

1. **`applications/`** - KubeVela Application manifests
   - These define **what** infrastructure to provision
   - Reference Timoni modules via the `timoni-module` component type
   - Provide values (VM size, location, network config, etc.)
   - Example: `test-vm.yaml` provisions a VM in existing VNet

2. **`definitions/`** - KubeVela ComponentDefinitions
   - These define **how** to deploy/render components
   - `timoni-module.yaml` - Teaches KubeVela how to use Timoni modules
     - Runs `timoni apply` in a Kubernetes Job
     - Passes values from Application to the module
   - `rbac.yaml` - Component for setting up RBAC in clusters

3. **Root `*.yaml` files** - Supporting manifests
   - `vm-crd.yaml` - Extracted VirtualMachine CRD (for quick install)
   - `azureserviceoperator_customresourcedefinitions_v2.16.0.yaml` - Full ASO2 CRD bundle
   - Other operator/controller manifests

**Flow Example:**
```yaml
# applications/test-vm.yaml references:
type: timoni-module  # <-- Uses definitions/timoni-module.yaml

# definitions/timoni-module.yaml runs:
timoni apply vm-instance oci://catalina.azurecr.io/vm-module
  --values <from-application>

# This renders timoni/modules/infra/vm/ templates into:
- VirtualMachine CR (ASO2)
- NetworkInterface CR (ASO2)
- PublicIPAddress CR (ASO2, optional)

# ASO2 operator sees these CRs and provisions Azure resources
```
```

## Resources

### Clusters (2)
- `dev-cluster-gitops` - Development cluster
- `staging-cluster-gitops` - Staging cluster

### Roles (2)
- `gitops-developer` - Developer role with create/update on dev cluster
- `gitops-viewer` - Read-only role across all clusters

### Subjects (1)
- `gitops-team` - Team group

### RBAC Definitions (3)
- `dev-rbac` - RBAC configuration for dev cluster
- `minikube-local-rbac` - RBAC configuration for local minikube
- `staging-rbac` - RBAC configuration for staging cluster

### Cron Definitions (2)
- `minikube-backup` - Bash job that runs every 15 minutes (backup simulation)
- `python-health-check` - Python health check job every 10 minutes

### Git Definitions (3)
- `demo-app-source` - Git source for demo application
- `test-ado-gitops` - Azure DevOps Git integration test
- `test-gitops-local` - Local Git integration test

### Project Examples (2)
- `demo-app-01` - Demo application with Helm chart using umbrella structure
  - Frontend component with Nginx
  - Backend component with Node.js
- `demo-app-02` - Placeholder for another demo application

## Usage

Create a GitDefinition CR pointing to this repository:

```yaml
apiVersion: ops-box.io/v1
kind: GitDefinition
metadata:
  name: test-gitops-repo
  namespace: ops-box
spec:
  repository:
    url: <path-to-this-repo>
  branches:
    - name: master
  paths:
    - path: "clusters/*.yaml"
      kind: RemoteCluster
    - path: "roles/*.yaml"
      kind: OpsBoxRole
    - path: "subjects/*.yaml"
      kind: OpsBoxSubject
    - path: "rbac-definitions/*.yaml"
      kind: RBACDefinition
      targetCluster: "minikube-local"  # Required for RBACDefinition
    - path: "cron-definitions/*.yaml"
      kind: CronDefinition
      targetCluster: "minikube-local"  # Required for CronDefinition
  pollIntervalSeconds: 300
  syncPolicy:
    automated:
      enabled: true
      prune: true
      selfHeal: true
```

The CC-Operator will:
1. Clone this repository
2. Parse YAML files matching the patterns
3. Extract `targetCluster` from path config for RBACDefinition/CronDefinition
4. Apply CRs via BFF-API to the specified cluster
5. Publish sync events
6. Auto-prune orphaned resources (if enabled)
7. Auto-heal drifted resources (if enabled)

## Important Notes

### RBACDefinition & CronDefinition
- These CRs **require** `targetCluster` in the GitDefinition path configuration
- The `targetCluster` field tells the git_handler which cluster to deploy to
- Example: `targetCluster: "minikube-local"` → deployed to `/api/v1/cron-definitions/minikube-local/{name}`

### Git-Ops Annotations
All synced resources will have these annotations:
- `ops-box.io/git-managed: "true"` - Marks resource as Git-managed
- `ops-box.io/git-source: <git-def-name>` - Source GitDefinition name
- `ops-box.io/git-branch: <branch>` - Git branch
- `ops-box.io/git-path: <path>` - Relative path in repo
- `ops-box.io/last-synced: <timestamp>` - Last sync timestamp

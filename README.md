# K8s-Ops-Box GitOps Test Repository

This repository contains sample k8s-ops-box Custom Resources for testing GitOps functionality.

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
└── cron-definitions/      # CronDefinition CRs (with targetCluster)
    ├── minikube-backup.yaml
    └── python-health-check.yaml
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

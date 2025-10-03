# K8s-Ops-Box GitOps Test Repository

This repository contains sample k8s-ops-box Custom Resources for testing GitOps functionality.

## Structure

```
.
├── clusters/          # RemoteCluster CRs
│   ├── dev-cluster.yaml
│   └── staging-cluster.yaml
├── roles/             # OpsBoxRole CRs
│   ├── developer-role.yaml
│   └── viewer-role.yaml
└── subjects/          # OpsBoxSubject CRs
    └── team-group.yaml
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

## Usage

Create a GitDefinition CR pointing to this repository:

```yaml
apiVersion: ops-box.io/v1
kind: GitDefinition
metadata:
  name: test-gitops-repo
  namespace: ops-box
spec:
  repoUrl: <path-to-this-repo>
  branch: master
  pollIntervalSeconds: 300
  pathPatterns:
    - "clusters/*.yaml"
    - "roles/*.yaml"
    - "subjects/*.yaml"
```

The CC-Operator will:
1. Clone this repository
2. Parse YAML files matching the patterns
3. Apply CRs via BFF-API
4. Publish sync events

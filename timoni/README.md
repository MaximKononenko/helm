# Timoni Modules

This directory contains [Timoni](https://timoni.sh/) modules used for infrastructure provisioning and application deployment.

## Directory Structure

The structure follows a separation of concerns between **Modules** (Producers) and **Projects** (Consumers), with modules further categorized by their role:

```text
helm/timoni/
├── modules/                 # Reusable Infrastructure Modules (Producers)
│   ├── infra/               # Cloud Infrastructure (ASO, Crossplane, etc.)
│   │   └── aks/             # AKS Module Source
│   ├── bootstrap/           # Cluster Bootstrap (ArgoCD, Ingress, etc.)
│   └── apps/                # Application Workloads
│
├── projects/                # Environment Implementations (Consumers)
│   └── <project-name>/      # e.g., "team-a-prod"
│       └── bundle.cue       # References modules via OCI
```

## Construct Levels

We organize our infrastructure code using the concept of Construct Levels (similar to AWS CDK):

- **L1 (Primitive Resources)**:
  - **What**: Automatically generated CUE schemas from Kubernetes CRDs (e.g., Azure Service Operator CRDs).
  - **Location**: `modules/<category>/<name>/cue.mod/gen/`
  - **Role**: Provide a 1:1 mapping to the underlying API resources.

- **L2 (Resource Templates)**:
  - **What**: CUE templates that wrap L1 resources with sensible defaults.
  - **Location**: `modules/<category>/<name>/templates/*.cue`
  - **Role**: Abstract away boilerplate.

- **L3 (Modules)**:
  - **What**: Complete, deployable modules.
  - **Location**: `modules/<category>/<name>/`
  - **Role**: Define high-level solutions (e.g., "Private AKS Cluster").

## Modules

### Infrastructure (`modules/infra`)
- **[aks](./modules/infra/aks)**: A module for provisioning Azure Kubernetes Service (AKS) clusters using Azure Service Operator (ASO).

### Bootstrap (`modules/bootstrap`)
- **[argocd](./modules/bootstrap/argocd)**: A module for bootstrapping ArgoCD (v2.12.7) on a new cluster.

### Applications (`modules/apps`)
- **[classic-nginx](./modules/apps/classic-nginx)**: A simple Nginx demo application (Stateless).
- **[classic-frontend-backend](./modules/apps/classic-frontend-backend)**: A multi-tier application pattern (Frontend + Backend).

## Projects

(Add your project bundles here)

## Construct Levels

We organize our infrastructure code using the concept of Construct Levels (similar to AWS CDK):

- **L1 (Primitive Resources)**:
  - **What**: Automatically generated CUE schemas from Kubernetes CRDs (e.g., Azure Service Operator CRDs).
  - **Location**: `cue.mod/gen/`
  - **Role**: Provide a 1:1 mapping to the underlying API resources. They offer full control but require verbose configuration and knowledge of the raw API.

- **L2 (Resource Templates)**:
  - **What**: CUE templates that wrap L1 resources with sensible defaults, type safety, and simplified interfaces.
  - **Location**: `templates/*.cue`
  - **Role**: Abstract away boilerplate and enforce specific configurations for individual resources (e.g., a standard VNet configuration).

- **L3 (Modules/Patterns)**:
  - **What**: Complete, deployable modules that compose multiple L2 resources into a cohesive architectural pattern.
  - **Location**: The Module itself (defined in `timoni.cue` and `values.cue`).
  - **Role**: Define high-level solutions, such as "A Private AKS Cluster with Hub-and-Spoke Networking". Users interact primarily with this level via `values.cue`.

## Projects vs. Modules

You might notice the nested structure (e.g., `aks-module/aks-module`). This distinction is intentional and serves a specific purpose:

1.  **The Project (Outer Folder)**:
    *   **Role**: The "Workspace" or "Home" for a specific infrastructure capability.
    *   **Contents**: Documentation, integration tests, CI/CD scripts, architectural diagrams, and the Module itself.
    *   **Example**: `helm/timoni/aks-module/`
    *   **Why**: Allows you to keep non-module assets separate from the distributable artifact. For example, you might have a Python script to validate the cluster *after* deployment; this script belongs in the Project, not inside the Timoni package.

2.  **The Module (Inner Folder)**:
    *   **Role**: The **Distributable Artifact**. This is what Timoni packages and pushes to the OCI registry.
    *   **Contents**: `timoni.cue`, `values.cue`, templates, and vendored schemas.
    *   **Example**: `helm/timoni/aks-module/aks-module/`
    *   **Why**: Keeps the package clean. When you run `timoni mod push`, only this folder is packaged. You don't want to push your CI scripts, local test notes, or project-level documentation to the container registry.

## Module Producer vs. Consumer

It is important to distinguish between **developing** a module and **using** a module.

### 1. The Producer (This Directory)
The structure you see here (`helm/timoni/aks-module/`) is optimized for **Module Authors**.
- We are building the blueprint.
- We need the source code (`aks-module/`), the tests (`test_values.cue`), and the documentation (`README.md`) together.
- The goal is to run `timoni mod push` to publish this artifact to a registry.

### 2. The Consumer (Your Clusters)
When you want to **use** this module to deploy a real cluster, you would typically create a separate "Bundle" or "Instance" project, potentially in a different repository or a `bundles/` directory.

That project would look like this:
```text
my-infrastructure/
├── production/
│   └── bundle.cue  # References oci://catalina.azurecr.io/aks-module:0.1.0
└── staging/
    └── bundle.cue  # References oci://catalina.azurecr.io/aks-module:0.1.0
```

In that model, the "Project" refers to the Module via its OCI URL, keeping them completely decoupled.

## Projects

- **[aks-module](./aks-module)**: A module for provisioning Azure Kubernetes Service (AKS) clusters using Azure Service Operator (ASO).

## Usage

To use these modules, you will typically:

1. Navigate to the module directory.
2. Create a `values.cue` file with your configuration.
3. Run `timoni build` to verify the output.
4. Run `timoni apply` to deploy the resources.

Refer to the specific project READMEs for detailed instructions.

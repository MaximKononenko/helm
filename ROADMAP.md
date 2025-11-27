# POC: AKS Cluster-as-a-Service with GitOps

**Objective:** Provision an AKS cluster, bootstrap it with ArgoCD, and deploy `demo-app-01` using a fully automated pipeline.

**Stack:**
-   **Orchestrator:** KubeVela (Primary), KRO (Secondary/Comparison)
-   **Infrastructure Provider (Azure):** Azure Service Operator v2 (ASO2)
-   **Infrastructure Provider (AWS - Future):** AWS Controllers for Kubernetes (ACK)
-   **Packaging:** Timoni (CUE)
-   **GitOps:** ArgoCD
-   *Note:* Crossplane is deferred. We are using a "Direct Provider" strategy (ASO2/ACK) to prioritize implementation speed and native API access over a unified abstraction layer.

## Requirements & Prerequisites
**1. Identity (Azure)**
-   **User Assigned Managed Identity (UAMI)** for ASO2.
-   **Permissions:**
    -   `Contributor` & `User Access Administrator` on the **Target Subscription** (to create RG, VNet, AKS).
    -   `Network Contributor` on the **Management VNet** (Hub) (to create Peering).
-   **Authentication Method (Choose One):**
    -   **Option A (Recommended):** Workload Identity Federation trusting the ASO2 ServiceAccount in the Management Cluster.
    -   **Option B (Fallback):** Service Principal with Client Secret (if Management Cluster does not support OIDC).

**2. Network**
-   **CIDR Block:** Dedicated CIDR (e.g., `/22` or `/24`) for the new POC Spoke VNet.
-   **Connectivity:** Route/Peering between Management VNet and new Spoke VNet (required for Management Cluster to reach new Private AKS API Server).
-   **DNS:** Ability for Management Cluster to resolve private AKS endpoints (`privatelink.*`).
-   **Firewall/Egress:** Whitelist `management.azure.com`, `login.microsoftonline.com`, `ghcr.io`, `docker.io`, `mcr.microsoft.com`.

**3. Artifacts**
-   **OCI Registry:** ACR or Artifactory with Read/Write access to store Timoni modules.

## Phase 1: Management Plane Setup
- [ ] **1.1 Prerequisites**: Verify/Install CLIs (az, timoni, vela, argocd).
- [ ] **1.2 Management Cluster**: Ensure local or remote management cluster is ready.
- [ ] **1.3 Install ASO2**: Deploy Azure Service Operator to Management Cluster.
- [ ] **1.4 Install KubeVela**: Deploy KubeVela Core to Management Cluster.
- [ ] **1.5 Install ArgoCD**: Deploy ArgoCD to Management Cluster (for observing the management plane itself).

## Phase 2: Infrastructure & Bootstrap Packaging (Timoni)
- [ ] **2.1 AKS Module**: Create `helm/timoni/aks-module`.
    -   *Strategy:* Define CUE modules that render native ASO2 resources:
        -   `ResourceGroup`
        -   `ManagedCluster` (AKS)
        -   `VirtualNetwork` (Spoke VNet)
        -   `VirtualNetworkPeering` (Bidirectional peering between Management VNet and new Spoke VNet).
- [ ] **2.2 ArgoCD Bootstrap Module**: Create `helm/timoni/argocd-module` importing the official Helm chart.
- [ ] **2.3 Demo App Module**: Create `helm/timoni/demo-app-01` for the application workload.

## Phase 3: Orchestration Implementation (KubeVela + ASO2)
- [ ] **3.1 Define KubeVela Component**: Create KubeVela Component definition consuming the Timoni AKS module.
- [ ] **3.2 Define Workflow**: Create the KubeVela Workflow:
    1.  **Provision**: Apply AKS Component (ASO2 resources including Peering).
    2.  **Wait**: Wait for `Ready` condition on ASO2 ManagedCluster and Peering.
    3.  **Retrieve Config**: Get Kubeconfig from ASO2 Secret.
    4.  **Bootstrap**: Deploy ArgoCD Timoni module to the *new* cluster using the retrieved config.

## Phase 4: Application Deployment (GitOps)
- [ ] **4.1 GitOps Config**: Define the `Application` CR for `demo-app-01`.
- [ ] **4.2 Deployment**: Commit changes and verify `demo-app-01` is running on the new AKS cluster.

## Phase 5: KRO Comparison (Optional)
- [ ] **5.1 KRO Setup**: Install KRO.
- [ ] **5.2 ResourceGroup Definition**: Define `AKSCluster` API in KRO.
- [ ] **5.3 Comparison**: Document pros/cons vs KubeVela.

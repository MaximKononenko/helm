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

## Testing Environment Details

**Management Cluster:**
-   **Name:** `aks-prd-eastus2-management`
-   **Resource Group:** `rg-prd-eastus2-mngmnt-compute`
-   **Subscription:** `az-us-pr` (999f85a0-ee38-4445-87b5-8d7a5897fa4d)
-   **OIDC Issuer:** Enabled (`https://eastus2.oic.prod-aks.azure.com/2eddc39c-2996-4c2a-ab97-f767c39ea155/ba299ca3-5c11-4a88-ab73-ab9cfb3f1bb8/`)
-   **Cluster Identity:** `uami-prd-eastus2-management` (Contributor on management RGs only)

**Target Environment (VM Test):**
-   **Subscription:** `Catalina-Vault-SQA` (a50f971b-376d-4d05-ac33-1e9fcfb8f32c)
-   **Resource Group:** `rg-tst-eastus-istio-compute`
-   **Location:** `eastus`
-   **VNet:** `vn-np-eastus-10-166-54-0-24` (in RG: `rg-np-eastus-dashboard`)
-   **Subnet:** `sn-tst-eastus-istio-10-166-54-0-26-aks-b` (10.166.54.0/26)

**Authentication:**
-   **Service Principal:** `puppetdeployment` (AppId: dcd9ad4b-3d70-4e89-8ddc-4e1636a15eeb)
-   **Permissions:** Contributor + Managed Identity Operator on `Catalina-Vault-SQA` subscription
-   **Client Secret:** Available

## Phase 1: Management Plane Setup
- [x] **1.1 Prerequisites**: Verify/Install CLIs (az, timoni, vela, argocd).
- [x] **1.2 Management Cluster**: Ensure local or remote management cluster is ready.
- [x] **1.3 Install ASO2**: Deploy Azure Service Operator to Management Cluster.
- [x] **1.4 Install KubeVela**: Deploy KubeVela Core to Management Cluster.
- [x] **1.5 Install ArgoCD**: Deploy ArgoCD to Management Cluster (for observing the management plane itself).

## Phase 2: Infrastructure & Bootstrap Packaging (Timoni)
- [x] **2.1 AKS Module**: Create `helm/timoni/modules/infra/aks`.
    -   *Strategy:* Define CUE modules that render native ASO2 resources:
        -   `ResourceGroup` (separate for AKS and Network)
        -   `ManagedCluster` (AKS)
        -   `VirtualNetwork` (Spoke VNet)
        -   `VirtualNetworkPeering` (Bidirectional peering between Management VNet and new Spoke VNet).
- [x] **2.2 ArgoCD Bootstrap Module**: Create `helm/timoni/modules/bootstrap/argocd` importing the official Helm chart.
- [x] **2.3 Demo App Module**: Create `helm/timoni/modules/apps/demo-app-01` for the application workload.
- [ ] **2.4 VM Module**: Create `helm/timoni/modules/infra/vm` for testing ASO2 with existing infrastructure.
    -   *Strategy:* Define CUE modules that render:
        -   `VirtualMachine` (Linux VM)
        -   `NetworkInterface` (attached to existing subnet)
        -   `PublicIPAddress` (optional)
        -   Use existing VNet/Subnet (no new network resources).

## Phase 3: Orchestration Implementation (KubeVela + ASO2)
- [x] **3.1 Define KubeVela Component**: Create KubeVela Component definition (`timoni-module`) consuming Timoni modules.
- [x] **3.2 AKS Workflow**: Create the KubeVela Application for full AKS provisioning:
    1.  **Provision**: Apply AKS Component (ASO2 resources including Peering).
    2.  **Wait**: Wait for `Ready` condition on ASO2 ManagedCluster and Peering.
    3.  **Retrieve Config**: Get Kubeconfig from ASO2 Secret.
    4.  **Bootstrap**: Deploy ArgoCD Timoni module to the *new* cluster using the retrieved config.
- [ ] **3.3 VM Test Flow**: Validate ASO2 + KubeVela integration with simpler resource:
    1.  **Configure Auth**: Create Kubernetes Secret with `puppetdeployment` SP credentials.
    2.  **Configure ASO2**: Update ASO2 to authenticate using the Service Principal.
    3.  **Create Application**: Define KubeVela Application using VM Timoni module.
    4.  **Deploy**: Apply the Application and verify VM is created in target subscription/RG.
    5.  **Validate**: Check VM status in Azure Portal and via `kubectl` ASO2 resources.

## Phase 4: Application Deployment (GitOps)
- [ ] **4.1 GitOps Config**: Define the `Application` CR for `demo-app-01`.
- [ ] **4.2 Deployment**: Commit changes and verify `demo-app-01` is running on the new AKS cluster.

## Phase 5: Use Case Patterns & Composition (Future)
- [ ] **5.1 Define Use Cases**: Document provisioning patterns:
    - **Greenfield**: Full provisioning (new RG, VNet, Subnet, Compute).
    - **Brownfield**: Use existing infrastructure (existing RG, VNet, Subnet).
    - **Hybrid**: Mix of new and existing resources (e.g., new compute in existing network).
- [ ] **5.2 Composition Strategy**: Design module composition approach:
    - **Option A**: Conditional logic within modules (current approach).
    - **Option B**: Separate modules per use case (e.g., `vm-greenfield`, `vm-brownfield`).
    - **Option C**: KubeVela Traits to inject/override components dynamically.
- [ ] **5.3 Template Library**: Create reusable KubeVela Application templates:
    - Template variables for common parameters (subscription, location, RG, etc.).
    - Policy configurations (RBAC, network policies, backup, monitoring).
    - Environment-specific overrides (dev, test, prod).
- [ ] **5.4 Self-Service Portal**: Design developer experience:
    - Input form/API for use case selection.
    - Parameter validation and defaults.
    - Cost estimation and approval workflow.

## Phase 6: KRO Comparison (Optional)
- [ ] **6.1 KRO Setup**: Install KRO.
- [ ] **6.2 ResourceGroup Definition**: Define `AKSCluster` API in KRO.
- [ ] **6.3 Comparison**: Document pros/cons vs KubeVela.

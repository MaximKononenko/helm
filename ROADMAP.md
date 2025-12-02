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
- [x] **2.4 VM Module**: Create `helm/timoni/modules/infra/vm` for testing ASO2 with existing infrastructure.
    -   *Strategy:* Define CUE modules that render:
        -   `VirtualMachine` (Linux VM)
        -   `NetworkInterface` (attached to existing subnet)
        -   `PublicIPAddress` (optional)
        -   Use existing VNet/Subnet (no new network resources).
    -   *Status:* Module created, tested, and validated. Successfully provisioned VM using brownfield networking.

## Phase 3: Orchestration Implementation (KubeVela + ASO2)
- [x] **3.1 Define KubeVela Component**: Create KubeVela Component definition (`timoni-module`) consuming Timoni modules.
- [x] **3.2 AKS Workflow**: Create the KubeVela Application for full AKS provisioning:
    1.  **Provision**: Apply AKS Component (ASO2 resources including Peering).
    2.  **Wait**: Wait for `Ready` condition on ASO2 ManagedCluster and Peering.
    3.  **Retrieve Config**: Get Kubeconfig from ASO2 Secret.
    4.  **Bootstrap**: Deploy ArgoCD Timoni module to the *new* cluster using the retrieved config.
- [x] **3.3 VM Test Flow (Timoni-only)**: Validated ASO2 integration with simpler resource:
    1.  ✅ **Configure Auth**: Created Secret `aso-credential-catalina-vault-sqa` with `puppetdeployment` SP credentials.
    2.  ✅ **Module Development**: Created VM Timoni module with ASO2 v2.16.0 CRDs vendored.
    3.  ✅ **Deploy**: Applied via `timoni bundle apply` - VM provisioned successfully.
    4.  ✅ **Validate**: Verified VM `vm-timoni-test-01` created in `rg-tst-eastus-istio-compute` with private IP 10.166.54.4.
    5.  ✅ **Cleanup**: Deleted via `timoni bundle delete` - ASO2 cleaned up Azure resources.
- [x] **3.4 VM Test Flow (KubeVela + Timoni)**: ✅ **COMPLETED** - Full orchestration loop validated:
    1.  ✅ **Create ComponentDefinition**: Created `timoni-module` Job-based component.
    2.  ✅ **RBAC**: ServiceAccount `vela-timoni-runner` with ASO2 permissions + namespace access.
    3.  ✅ **Custom Image**: Built Alpine-based Timoni image with CA certs for ACR access.
    4.  ✅ **ACR Authentication**: Docker-registry secret mounted for OCI module pulls.
    5.  ✅ **Key Discovery**: JSON values fail with "undefined value" - **CUE format required**.
    6.  ✅ **Solution**: Generate CUE values (`values: {...json...}`) instead of plain JSON.
    7.  ✅ **Deploy**: Applied Application - Job succeeded, ASO2 created VM resources.
    8.  ✅ **Validate**: VM `vm-vela-test-01` provisioned in Azure (Standard_B2s, no public IP).
    9.  ⚠️ **Limitation**: Job-based approach doesn't handle Update/Delete lifecycle.
    10. 📝 **Cleanup**: Manual `timoni delete` required for resource deletion.
- [x] **3.5 VM Self-Service (KubeVela Native)**: ✅ **COMPLETED** - Direct ASO2 integration without Timoni:
    1.  ✅ **ComponentDefinition**: Created `azure-vm` with native ASO2 CRDs (no Job wrapper).
    2.  ✅ **CUE Patterns**: Implemented mappings, conditionals, loops, validation:
        - User-friendly size selection: `small/medium/large` → Azure SKUs
        - Environment-aware sizing: dev vs prod use different SKUs
        - Tag merging: User tags + platform defaults
        - Conditional resources: Public IP only if enabled
        - Validation: Regex for naming, constraints for disk size
    3.  ✅ **Application Template**: Simplified user interface - only essential params
    4.  ✅ **Documentation**: Created `CUE_PATTERNS.md` with examples
    5.  ✅ **Deploy Test**: Native Application validated - full CUD lifecycle working
    6.  ✅ **Traits Demo**: Implemented 4 TraitDefinitions (backup, cost, security, monitoring)
    7.  ✅ **API Integration**: Documented REST API calls in Demo 5
    8.  ✅ **Comparison**: Full comparison matrix in `helm/DEMOS.md`
- [x] **3.6 Data Disk Management**: ✅ **COMPLETED** - Separate Disk resources with tag inheritance:
    1.  ✅ **Disk CRD**: Installed compute.azure.com/v1api20200930 Disk CRD
    2.  ✅ **ComponentDefinition Update**: Implemented separate Disk resources via outputs
    3.  ✅ **Disk Creation**: Used `createOption: "Attach"` with managedDisk.reference
    4.  ✅ **Tag Inheritance**: Data disks inherit User + Platform tags (not trait tags)
    5.  ✅ **Testing**: Validated 2-disk scenario (256GB Premium_LRS, 128GB StandardSSD_LRS)
    6.  ✅ **Documentation**: Updated Demo 6 with data disk substep and key learnings
- [x] **3.7 ASO2 CRD Management**: ✅ **COMPLETED** - Organized CRD lifecycle:
    1.  ✅ **Directory Structure**: Created `helm/aso2/` with live subfolder
    2.  ✅ **CRD Organization**: Separated VM, AKS, and Disk CRDs
    3.  ✅ **Operator Restart**: Documented webhook registration requirement
    4.  ✅ **Documentation**: Created README with extraction examples

## Phase 4: Application Deployment (GitOps)
- [ ] **4.1 GitOps Config**: Define the `Application` CR for `demo-app-01`.
- [ ] **4.2 Deployment**: Commit changes and verify `demo-app-01` is running on the new AKS cluster.

## Phase 5: Platform Architecture & Tooling Strategy

### **5.1 Architecture Decision: Two-Path Approach** ✅
**Infrastructure (Platform/Self-Service):**
- **Path**: Your UI → KubeVela API → ASO2 CRDs → Azure
- **Tool**: KubeVela with native ASO2 ComponentDefinitions
- **Benefits**: 
  - Full CUD lifecycle management
  - OAM abstraction with Traits
  - Policy enforcement via CUE
  - Direct Kubernetes API (no CLI needed)
- **Use Cases**:
  - VM provisioning (brownfield operations)
  - AKS cluster provisioning (greenfield projects - Platform Engineers)
  - Network resource management
  - Self-service with guardrails (limited RG/size choices)

**Application Workloads (Developers):**
- **Path**: Git → ArgoCD → Timoni Modules (OCI) → Kubernetes
- **Tool**: Timoni + ArgoCD
- **Benefits**:
  - Module versioning and distribution
  - GitOps pull model
  - Vendored dependencies
  - Developer consumption of pre-built patterns
- **Use Cases**:
  - Microservices deployment
  - Stateful applications (databases)
  - Reusable application patterns

### **5.2 ComponentDefinition Patterns (KubeVela)** 🎯
- [x] **5.2.1 Native ASO2 Pattern**: Direct CRD management (preferred)
  - Files: `helm/vela/definitions/azure-vm.yaml`
  - Pattern: CUE template → ASO2 resources
  - Lifecycle: Full CUD via KubeVela controller
- [x] **5.2.2 Job Wrapper Pattern**: External tool execution (fallback)
  - Files: `helm/vela/definitions/timoni-module.yaml`
  - Pattern: Job executes CLI tool (timoni, terraform, etc.)
  - Limitation: Create-only, manual cleanup
- [ ] **5.2.3 Trait Library**: Cross-cutting concerns
  - Backup policies
  - Cost tagging
  - Security baselines
  - Monitoring/observability

### **5.3 Use Case Patterns & Composition**
- [x] **5.3.1 Define Use Cases**: ✅ **COMPLETED** - Documented provisioning patterns:
    - **Greenfield**: Full provisioning (new RG, VNet, Subnet, Compute) - Platform Engineers
    - **Brownfield**: Use existing infrastructure (existing RG, VNet, Subnet) - Self-Service (Demo 08)
    - **Hybrid**: Mix of new and existing resources (e.g., new compute in existing network) - Default pattern
- [x] **5.3.2 Composition Strategy**: CUE-based approach within ComponentDefinitions:
    - ✅ Conditional logic for optional resources (public IP)
    - ✅ Mappings for user-friendly abstractions (size → SKU)
    - ✅ Environment-aware configurations (dev vs prod)
    - ✅ Validation and policy enforcement
    - 📝 See: `helm/vela/CUE_PATTERNS.md`
- [x] **5.3.3 Template Library**: ✅ **COMPLETED** - Reusable KubeVela Application templates:
    - ✅ Demo 4: Basic VM with network configuration
    - ✅ Demo 5: REST API integration patterns
    - ✅ Demo 6: Trait composition (3 scenarios: full, minimal, data disks)
    - ✅ Demo 08: Import/adoption templates (8 substeps)
- [ ] **5.3.4 Self-Service Portal (Demo 07)**: 🎯 **IN PROGRESS** - Approval workflow design:
    - ✅ Design Discussion: Created comprehensive options document
    - [ ] OPA Integration: Policy-based auto-approval vs manual approval
    - [ ] Notification: Slack + Microsoft Teams webhooks
    - [ ] TargetProcess Integration: Link approvals to tickets
    - [ ] Monitoring: Audit trail to Datadog + Grafana dashboards
    - [ ] RBAC: Role-based approvers with emergency bypass
    - [ ] Cost Estimation: Calculate VM + trait costs for approval decision

## Phase 6: Demo 07 - Approval Workflows (Governance)
**Goal**: Multi-stage approval for infrastructure changes with policy validation

**Location**: `helm/demos/demo-infra-vm-07-workflows/`

**Tech Stack**:
- **Workflow Engine**: KubeVela Workflow (suspend steps)
- **Policy Validation**: OPA (Open Policy Agent) for auto-approval decisions
- **Notifications**: Slack + Microsoft Teams webhooks
- **Ticketing**: TargetProcess integration
- **Monitoring**: Datadog + Grafana (Prometheus stack) for audit trail
- **RBAC**: Kubernetes RBAC for role-based approvers

**Key Design Questions** (see Demo 07 README for details):
1. **Approver Management**: How to define who can approve? (ConfigMap vs LDAP vs external service)
2. **Notification Method**: How to notify approvers? (Slack, Teams, Email, multi-channel)
3. **Multi-Stage Logic**: Sequential vs parallel approvals? (team lead → finance vs both together)
4. **OPA Integration**: When to auto-approve? (compliant small VMs vs all need approval)
5. **Emergency Bypass**: Break-glass mechanism for outages? (Who has permission, how to audit)
6. **TargetProcess Integration**: Link to existing tickets? (Mandatory vs optional)
7. **Cost Estimation**: Show VM + trait costs? (Accuracy requirements for approval decision)

**Implementation Phases**:
- [ ] **6.1 Design Review**: Finalize tech stack and architectural decisions
- [ ] **6.2 Simple Approval**: Single suspend step with manual resume
- [ ] **6.3 Slack/Teams Notifications**: Webhook integration with approval buttons
- [ ] **6.4 OPA Policy Engine**: Auto-approve compliant requests, block violations
- [ ] **6.5 Multi-Stage Approvals**: Sequential chains (team lead → finance → security)
- [ ] **6.6 Cost Estimation**: Calculate monthly VM + trait costs
- [ ] **6.7 TargetProcess Integration**: Link approvals to tickets
- [ ] **6.8 Audit Trail**: Export events to Datadog, create Grafana dashboards
- [ ] **6.9 Emergency Bypass**: Break-glass role with mandatory audit
- [ ] **6.10 Documentation**: Complete Demo 07 with examples and screenshots

## Phase 7: Demo 08 - Importing Existing VMs (Brownfield)
**Goal**: Adopt existing Azure VMs into KubeVela management without recreation

**Location**: `helm/demos/demo-infra-vm-08-import/`

**Substeps** (progressive complexity):
- [ ] **7.1 Basic Import (08.1)**: Single VM with `asoctl import`
- [ ] **7.2 Dependencies (08.2)**: Import VM + NICs + Disks + NSGs
- [ ] **7.3 KubeVela Wrap (08.3)**: Convert raw ASO2 to KubeVela Application
- [ ] **7.4 Apply Traits (08.4)**: Add backup/monitoring/security to imported VMs
- [ ] **7.5 Bulk Import (08.5)**: Script to import 100+ VMs automatically
- [ ] **7.6 Terraform Migration (08.6)**: Import Terraform-managed VMs, remove from tfstate
- [ ] **7.7 Drift Detection (08.7)**: Compare imported config vs Azure reality
- [ ] **7.8 Templates (08.8)**: Reusable import playbook for production

**Priority**: Phase 1 (08.1-08.3) for immediate brownfield needs

## Phase 8: Migration from Terraform/Terragrunt 🎯
- **Goal**: Replace infrastructure pipelines with KubeVela + ASO2
- **Benefits**:
  - Declarative state in Kubernetes
  - No separate Terraform state management
  - Native RBAC and policy enforcement
  - API-driven (UI integration ready)
  - GitOps-compatible (optional)
- **Challenges**:
  - Existing Terragrunt projects need mapping to ComponentDefinitions
  - State migration strategy (use Demo 08 patterns)
  - Team training on CUE/KubeVela

## Phase 9: KRO Comparison (Optional)
- [ ] **9.1 KRO Setup**: Install KRO.
- [ ] **9.2 ResourceGroup Definition**: Define `AKSCluster` API in KRO.
- [ ] **9.3 Comparison**: Document pros/cons vs KubeVela.

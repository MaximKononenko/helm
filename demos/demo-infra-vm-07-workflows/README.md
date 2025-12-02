# Demo 7: Approval Workflows - Design Discussion

**Status**: 🔜 Planning Phase  
**Date**: December 1, 2025

## Overview

Design and implement approval workflows for infrastructure provisioning using KubeVela's workflow capabilities.

## Tech Stack

**Workflow & Orchestration**:
- KubeVela Workflow (suspend steps, notifications)
- Policy Engine: **Kyverno** OR **OPA** (see comparison below)

**Notifications & Communication**:
- Slack webhooks (primary)
- Microsoft Teams webhooks (secondary)
- Both supported for approver flexibility

**Monitoring & Audit**:
- Datadog for event ingestion and dashboards
- Grafana for visualization (Prometheus stack)
- Kubernetes events for workflow state

**Ticketing & ITSM**:
- TargetProcess integration
- Link approvals to existing tickets

**Authentication & Authorization**:
- Kubernetes RBAC for role-based approvers
- ServiceAccounts for workflow execution

## Policy Engine Comparison: Kyverno vs OPA

### Overview

Both Kyverno and OPA can validate Kubernetes resources before they reach the approval workflow. Here's the tradeoff analysis:

| Criteria | Kyverno | OPA (with Gatekeeper) |
|----------|---------|----------------------|
| **Policy Language** | YAML (native K8s syntax) | Rego (custom DSL) |
| **Learning Curve** | ✅ Low - uses familiar K8s patterns | ⚠️ Medium-High - new language to learn |
| **Kubernetes Focus** | ✅ Native K8s only, optimized for it | ⚠️ General-purpose (K8s, VMs, APIs, databases) |
| **Policy Complexity** | ⚠️ Limited to K8s resource patterns | ✅ Highly expressive, complex logic trees |
| **Validation** | ✅ Block non-compliant resources | ✅ Block non-compliant resources |
| **Mutation** | ✅ Built-in (add labels, inject values) | ⚠️ Via Gatekeeper mutations (limited) |
| **Resource Generation** | ✅ Auto-create ConfigMaps, Secrets, etc. | ❌ Not supported |
| **Policy Reports** | ✅ Native PolicyReport CRDs | ⚠️ Requires external tools |
| **Prometheus Integration** | ✅ Native metrics export | ⚠️ Requires custom exporters |
| **Grafana Dashboards** | ✅ Pre-built dashboards available | ⚠️ Custom dashboards needed |
| **Datadog Integration** | ✅ Via Prometheus metrics scraping | ✅ Via custom exporters |
| **Installation Size** | ✅ ~50MB (lightweight) | ⚠️ ~200MB (heavier runtime) |
| **Performance** | ✅ Fast (native Go, K8s-optimized) | ⚠️ Slower (embedded Rego runtime) |
| **CLI Tools** | ✅ `kyverno` CLI for testing | ✅ `opa` CLI, `conftest` |
| **IDE Support** | ⚠️ YAML linting only | ✅ VS Code extensions for Rego |
| **Community** | ✅ CNCF Incubating (growing) | ✅ CNCF Graduated (mature) |
| **Multi-System Policies** | ❌ K8s only | ✅ Can validate Azure APIs, Terraform, etc. |
| **Cost Calculation Logic** | ⚠️ Limited (simple comparisons) | ✅ Complex cost rules, external data |
| **External API Calls** | ❌ Not supported | ✅ Can query external services |
| **Dry-Run Testing** | ✅ `kyverno apply --dry-run` | ✅ `opa test` with unit tests |
| **Policy-as-Code** | ✅ YAML in Git | ✅ Rego in Git |

### Use Case Analysis

#### ✅ **Use Kyverno If**:
1. **Simple validation** - Required tags, naming conventions, resource limits
2. **Auto-remediation** - Add missing tags, inject defaults
3. **Team familiarity** - Team already knows YAML, wants fast adoption
4. **Native K8s only** - Not validating external systems (Azure APIs, Terraform)
5. **Quick setup** - Need policy enforcement running in <1 hour
6. **Prometheus stack** - Already using Prometheus + Grafana
7. **Resource generation** - Need to auto-create related resources

**Example Kyverno Policy**:
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-vm-tags
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-owner-tag
      match:
        resources:
          kinds: [Application]
          namespaces: [azureserviceoperator-system]
      validate:
        message: "All VMs must have Owner, CostCenter, Environment tags"
        pattern:
          spec:
            components:
              - type: azure-vm
                properties:
                  tags:
                    Owner: "?*"
                    CostCenter: "?*"
                    Environment: "dev|test|staging|prod"
```

#### ✅ **Use OPA If**:
1. **Complex logic** - Multi-condition decision trees, budget calculations
2. **External integrations** - Query TargetProcess API, Azure Cost Management
3. **Multi-system** - Validate Terraform configs, Azure ARM templates
4. **Advanced testing** - Need unit tests, mocking, test coverage
5. **Reusable policies** - Policies shared across K8s, CI/CD, Terraform
6. **Data aggregation** - Compare VM request against department quota/budget
7. **Team expertise** - Team comfortable learning Rego

**Example OPA Policy** (Rego):
```rego
package kubevela.approval

import future.keywords.in

# Auto-approve small dev/test VMs with compliant tags
auto_approve {
    input.component.properties.environment in ["dev", "test"]
    input.component.properties.vmSize == "small"
    has_required_tags
    monthly_cost < 100
}

# Require approval for production or large VMs
requires_approval {
    input.component.properties.environment == "prod"
}

requires_approval {
    input.component.properties.vmSize in ["large", "xlarge"]
}

requires_approval {
    monthly_cost >= 100
}

# Calculate monthly cost based on VM size
monthly_cost = cost {
    size_costs := {
        "small": 50,
        "medium": 100,
        "large": 250,
        "xlarge": 500
    }
    cost := size_costs[input.component.properties.vmSize]
}

# Validate required tags
has_required_tags {
    input.component.properties.tags.Owner
    input.component.properties.tags.CostCenter
    input.component.properties.tags.Environment
}

# Block VMs without required tags
deny[msg] {
    not has_required_tags
    msg := "VM missing required tags: Owner, CostCenter, Environment"
}
```

### Recommended Approach

#### **Option A: Kyverno Only** (Simpler)
✅ **Best for**: Fast implementation, K8s-only policies, team prefers YAML

**Architecture**:
```
User Request
    ↓
Kyverno Admission (validate + mutate)
    ↓ (if invalid: reject immediately)
    ↓ (if valid: continue)
KubeVela Workflow
    ↓
Simple approval logic (vmSize, environment)
    ↓
Manual approval or auto-provision
```

**Pros**: 
- Fast to implement (hours, not days)
- No new language to learn
- Native Prometheus metrics for Grafana
- Auto-add missing tags via mutation

**Cons**:
- Limited complex logic (cost calculations, external APIs)
- Can't query TargetProcess or budget systems
- Harder to unit test policies

#### **Option B: Kyverno + OPA** (Hybrid)
✅ **Best for**: Complex approval logic, external integrations, future-proof

**Architecture**:
```
User Request
    ↓
Kyverno Admission (basic validation + mutation)
    ↓ (block invalid immediately)
    ↓ (add platform tags)
KubeVela Workflow
    ↓
OPA Evaluation (complex cost/budget/approval logic)
    ↓
    ├─ Auto-approve (OPA says ok) → Provision
    │
    └─ Requires approval (OPA says manual) → Suspend workflow
        ↓
        Slack/Teams notification
        ↓
        Manual approval
        ↓
        Provision
```

**Layer 1 (Kyverno)**: Pre-flight checks
- Required tags present
- Valid environment (dev/test/staging/prod)
- VM name matches regex pattern
- Auto-add ManagedBy, Platform tags

**Layer 2 (OPA)**: Approval routing
- Calculate monthly cost (VM + traits)
- Check department budget (external API call)
- Determine approver(s) based on cost/environment
- Link to TargetProcess ticket if required

**Pros**:
- Best of both worlds
- Kyverno handles simple validation
- OPA handles complex business logic
- Scalable for future requirements

**Cons**:
- Two systems to maintain
- More complex architecture
- Team needs to learn Rego (for OPA policies)

#### **Option C: OPA Only** (Complex)
⚠️ **Best for**: Teams already using OPA, need maximum flexibility

**Pros**: Single policy engine, maximum expressiveness
**Cons**: Steeper learning curve, heavier resource usage

### Decision Matrix

| Your Requirement | Kyverno Only | Kyverno + OPA | OPA Only |
|------------------|--------------|---------------|----------|
| **Simple tag validation** | ✅ Perfect | ✅ Works | ⚠️ Overkill |
| **Auto-add missing tags** | ✅ Built-in | ✅ Kyverno | ❌ Not supported |
| **Complex cost logic** | ❌ Limited | ✅ OPA | ✅ Perfect |
| **TargetProcess API** | ❌ No | ✅ OPA | ✅ Perfect |
| **Department budget check** | ❌ No | ✅ OPA | ✅ Perfect |
| **Grafana dashboards** | ✅ Native | ✅ Both | ⚠️ Custom |
| **Team learning curve** | ✅ Easy | ⚠️ Medium | ❌ Hard |
| **Implementation time** | ✅ 1-2 days | ⚠️ 1 week | ❌ 2+ weeks |
| **Future extensibility** | ⚠️ Limited | ✅ Excellent | ✅ Excellent |

### Recommendation for Demo 07

**Start with: Kyverno Only (Option A)**
- Implement basic policies in 1-2 days
- Validate required tags, enforce naming
- Auto-add platform tags (ManagedBy, Platform)
- Get approval workflow running quickly

**Migrate to: Kyverno + OPA (Option B)** when:
- Need complex cost calculations
- Want to query TargetProcess or budget APIs
- Approval logic becomes too complex for workflow alone
- Need to validate Terraform or Azure ARM templates

This approach gives you **quick wins now** with **extensibility later**.

## Use Cases

### 1. High-Cost Resources
- VM sizes larger than Standard_D4s_v3 require manager approval
- Resources with estimated monthly cost > $500 require finance approval

### 2. Production Environments
- Any production resource requires 2-stage approval (Team Lead → Operations)
- Deletion of production resources requires 3-stage approval (Team Lead → Operations → VP)

### 3. Compliance Requirements
- Resources with `securityLevel: restricted` require security team approval
- Resources with `complianceFramework: pci-dss` or `hipaa` require compliance officer approval

### 4. Budget Controls
- Department budgets require CFO approval when 80% utilized
- Cross-department resource sharing requires both department heads

## KubeVela Workflow Capabilities

### Built-in Step Types
- `suspend`: Pause workflow and wait for manual approval
- `notification`: Send notifications (webhook, email, slack, dingtalk)
- `apply-component`: Apply resources after approval
- `webhook`: Call external systems (approval systems, ITSM)

### Workflow Status
- `running`: Executing steps
- `suspending`: Waiting for approval
- `succeeded`: Approved and completed
- `failed`: Rejected or errored
- `terminated`: Manually cancelled

## Proposed Architecture

```
User Request (kubectl/API/UI)
    ↓
KubeVela Application with Workflow
    ↓
Step 1: CUE Validation (syntax, required fields)
    ↓
Step 2: OPA Policy Check (compliance, security, cost)
    ↓
    ├─ Auto-Approve (compliant low-risk) → Skip to Step 5
    │
    └─ Requires Approval → Step 3
        ↓
Step 3: Cost Estimation (VM + traits)
    ↓
Step 4: Suspend for Approval
    ↓
    ├─ Notification → Slack + Teams
    │   ↓
    │   Approver receives notification
    │   ↓
    │   Approve/Reject (kubectl/API/UI)
    │   ↓
    │   Audit event → Datadog
    ↓
Step 5: Conditional - If Approved
    ↓
Step 6: Apply Resources (ASO2)
    ↓
Step 7: Update TargetProcess ticket
    ↓
Step 8: Notification (Success) → Slack + Teams
    ↓
Step 9: Final Audit → Datadog + Grafana
```

## Key Questions

### 1. Approval Interface
**Options:**
- A. **kubectl resume workflow** - Command-line approval
- B. **REST API** - Custom UI sends approval via K8s API
- C. **TargetProcess Integration** - Integrate with existing ticketing system

**Recommendation**: Start with B (REST API) for UI integration, add C (TargetProcess) for ITSM workflow

**Note**: We use TargetProcess as our ticketing system, not ServiceNow or Jira

### 2. Approver Selection
**Options:**
- A. **Hardcoded in workflow** - Static approvers per workflow type
- B. **ConfigMap lookup** - Approvers mapped by resource type/department
- C. **External service** - Query LDAP/Azure AD for approvers

**Recommendation**: B (ConfigMap) for flexibility, migrate to C for production

### 3. Notification Method
**Options:**
- A. **Slack** - Webhook + interactive messages (primary notification channel)
- B. **Microsoft Teams** - Webhook + adaptive cards (secondary channel)
- C. **Both** - Multi-channel notifications for approver flexibility
- D. **Email** - SMTP fallback for offline approvers

**Recommendation**: C (Both Slack + Teams) since we use both, with Slack as primary

**Implementation Notes**:
- Slack: Block Kit for rich messages with approval buttons
- Teams: Adaptive Cards with actionable buttons
- Webhook URLs stored in ConfigMap or Secret
- Message templates include: requester, resource details, cost estimate, approve/reject actions

### 4. Audit Trail
**Options:**
- A. **Workflow events** - K8s events on Application resource
- B. **Database** - External PostgreSQL for audit
- C. **Datadog + Grafana** - Send events to Datadog, visualize in Grafana dashboards

**Recommendation**: A + C for compliance (K8s native + Datadog integration)

**Datadog Integration**:
- Use Datadog Agent DaemonSet to collect K8s events
- Tag events with: workflow_name, requester, approver, decision, resource_type
- Create Datadog monitors for: approval timeouts, rejected requests, emergency bypass usage
- Build Grafana dashboards for: approval SLA metrics, approver activity, compliance reports
- Retention: 90 days in Datadog (configurable)

### 5. Policy Validation Strategy
**Question**: Which policy engine(s) should we use for validation and auto-approval?

**Options:**
- A. **Kyverno Only** - Simple YAML policies for validation + mutation (fastest to implement)
- B. **OPA Only** - Complex Rego policies for advanced logic (most flexible)
- C. **Hybrid (Kyverno + OPA)** - Kyverno for validation, OPA for approval routing (recommended)
- D. **All Manual** - No policy automation, every request needs human approval (safest, slowest)

**Recommendation**: Start with A (Kyverno Only), migrate to C (Hybrid) when needed

**See detailed comparison table above** for Kyverno vs OPA tradeoffs.

**Use Cases**:
- **Block immediately**: VMs without required tags (Owner, CostCenter, Environment)
- **Auto-remediate**: Add missing platform tags (ManagedBy, Platform)
- **Auto-approve**: Small VMs (Standard_B2s) in dev/test with compliant tags
- **Require approval**: Large VMs (Standard_D4+), production environment, premium disks
- **Emergency bypass**: Specific RBAC role can skip all checks (audited)

**Kyverno Policy Example** (simpler):
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: vm-validation
spec:
  validationFailureAction: Enforce
  rules:
    - name: require-tags
      match:
        resources:
          kinds: [Application]
      validate:
        message: "VMs need Owner, CostCenter, Environment tags"
        pattern:
          spec:
            components:
              - type: azure-vm
                properties:
                  tags:
                    Owner: "?*"
                    CostCenter: "?*"
                    Environment: "dev|test|staging|prod"
    
    - name: auto-add-platform-tags
      match:
        resources:
          kinds: [Application]
      mutate:
        patchStrategicMerge:
          spec:
            components:
              - type: azure-vm
                properties:
                  tags:
                    ManagedBy: "kubevela"
                    Platform: "ops-box"
```

**OPA Policy Example** (more complex logic):
```rego
package kubevela.approval

# Auto-approve dev/test small VMs
auto_approve {
    input.component.properties.environment in ["dev", "test"]
    input.component.properties.vmSize == "small"
    has_required_tags
    monthly_cost < 100
}

# Require approval for production or high cost
requires_approval {
    input.component.properties.environment == "prod"
}

requires_approval {
    monthly_cost >= 100
}

# Calculate cost based on VM size + traits
monthly_cost = cost {
    base_cost := vm_costs[input.component.properties.vmSize]
    trait_cost := count(input.traits) * 20  # $20/trait
    cost := base_cost + trait_cost
}

vm_costs := {
    "small": 50,
    "medium": 100,
    "large": 250,
    "xlarge": 500
}
```

### 6. TargetProcess Integration
**Question**: How to integrate with TargetProcess ticketing system?

**Options:**
- A. **Optional Link** - Users can provide TP ticket ID in request metadata
- B. **Mandatory Link** - Require TP ticket for all production resources
- C. **Auto-Create** - Workflow creates TP ticket automatically
- D. **Bi-directional** - Approving in TP updates KubeVela workflow

**Recommendation**: A for dev/test, B for production resources

**Implementation**:
- TP REST API integration in workflow step
- Webhook from TP to KubeVela on ticket approval
- Store TP ticket URL in Application annotations
- Include TP ticket link in Slack/Teams notifications

### 7. Timeout Handling
**Options:**
- A. **Auto-reject** - Safer, requires re-submission
- B. **Auto-approve** - Risky, only for low-impact resources
- C. **Escalate** - Notify higher authority after timeout

**Recommendation**: A for most resources, C for time-sensitive dev/test

## Technical Implementation

### Workflow Definition Example

```yaml
apiVersion: core.oam.dev/v1beta1
kind: Application
metadata:
  name: vm-with-approval
  namespace: azureserviceoperator-system
spec:
  components:
    - name: my-vm
      type: azure-vm
      properties:
        vmName: "vm-prod-01"
        vmSize: "large"  # Triggers approval
        environment: "prod"  # Triggers approval
        # ... other properties
  
  workflow:
    steps:
      - name: validate-request
        type: apply-component
        properties:
          component: my-vm
      
      - name: estimate-cost
        type: step-group
        # Calculate monthly cost based on vmSize + traits
      
      - name: notify-approver
        type: notification
        properties:
          webhook:
            url: "https://outlook.office.com/webhook/..."
            message:
              title: "VM Approval Required"
              text: |
                User: {{ .context.requester }}
                VM: {{ .component.my-vm.properties.vmName }}
                Size: {{ .component.my-vm.properties.vmSize }}
                Environment: {{ .component.my-vm.properties.environment }}
                Estimated Cost: ${{ .workflow.estimate-cost.monthlyCost }}
                
                To approve: kubectl vela workflow resume vm-with-approval -n azureserviceoperator-system
      
      - name: wait-for-approval
        type: suspend
        timeout: "24h"
      
      - name: provision-vm
        type: apply-component
        if: {{ .workflow["wait-for-approval"].approved }}
        properties:
          component: my-vm
      
      - name: notify-completion
        type: notification
        properties:
          webhook:
            url: "https://outlook.office.com/webhook/..."
            message:
              title: "VM Provisioned"
              text: "VM {{ .component.my-vm.properties.vmName }} is ready"
```

### Approval ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: approval-matrix
  namespace: vela-system
data:
  # VM size thresholds
  vm-size-approval: |
    small: none
    medium: none
    large: team-lead
    xlarge: team-lead,finance
  
  # Environment approvers
  environment-approval: |
    dev: none
    test: none
    staging: team-lead
    prod: team-lead,operations
  
  # Security level approvers
  security-approval: |
    public: none
    internal: none
    confidential: security-team
    restricted: security-team,compliance
  
  # Approver contacts
  approvers: |
    team-lead: team-lead@company.com
    finance: finance-team@company.com
    operations: ops-team@company.com
    security-team: security@company.com
    compliance: compliance@company.com
```

### Custom Workflow Steps

**Option 1**: CUE-based workflow step
```cue
// helm/vela/definitions/approval-step.cue
import "vela/op"

approval: {
  #do: "steps"
  #provider: "builtin"
  
  // Get approval requirements
  requirements: op.#Steps & {
    getApprovers: op.#Read & {
      value: {
        apiVersion: "v1"
        kind: "ConfigMap"
        metadata: {
          name: "approval-matrix"
          namespace: "vela-system"
        }
      }
    }
  }
  
  // Send notification
  notify: op.#HTTPDo & {
    method: "POST"
    url: parameter.webhook
    request: {
      body: {
        title: "Approval Required"
        requester: context.requester
        resource: parameter.resourceName
        approvers: requirements.getApprovers.value.data[parameter.approvalType]
      }
    }
  }
  
  parameter: {
    webhook: string
    resourceName: string
    approvalType: string
  }
}
```

**Option 2**: External approval service
```bash
# Microservice that handles approval logic
POST /api/v1/approvals
{
  "resource": "vm-prod-01",
  "requester": "user@company.com",
  "type": "vm-large-prod",
  "details": {
    "vmSize": "large",
    "environment": "prod",
    "estimatedCost": 850
  }
}

# Returns approval ID
{
  "approvalId": "ap-12345",
  "status": "pending",
  "approvers": ["team-lead@company.com", "ops-team@company.com"],
  "expiresAt": "2025-12-02T12:00:00Z"
}

# Workflow polls this endpoint
GET /api/v1/approvals/ap-12345
{
  "status": "approved",
  "approvedBy": "team-lead@company.com",
  "approvedAt": "2025-12-01T14:30:00Z",
  "comments": "Approved for Q4 project"
}
```

## Discussion Topics

1. **Approver Management**
   - How do we define who can approve what?
   - Should approvers be in ConfigMap, LDAP, or external service?
   - Do we need approval hierarchies (manager → director → VP)?

2. **Notification Preferences**
   - Should approvers choose their notification method?
   - Do we need in-app notifications in addition to email/Teams?
   - How do we handle approvers in different time zones?

3. **Multi-Stage Approvals**
   - Sequential (one after another) or parallel (all at once)?
   - What if one approver rejects but others approve?
   - Should we allow partial approvals (e.g., "approved but reduce VM size")?

4. **Emergency Bypass**
   - Should there be a break-glass mechanism?
   - Who can bypass approvals in emergencies?
   - How do we audit bypass actions?

5. **Integration with TargetProcess (ITSM)**
   - Should we integrate with TargetProcess ticketing system?
   - Optional link (user provides ticket ID) vs mandatory (required for prod)?
   - Auto-create TP ticket for each approval request?
   - Bi-directional sync (approving in TP updates KubeVela workflow)?
   - Should approvals be tracked in TP for compliance audits?

6. **User Experience**
   - How does a user know their request is pending approval?
   - Can users see approval status in real-time?
   - Should users be able to cancel pending requests?

7. **Cost Estimation**
   - How accurate should cost estimates be?
   - Should we include only VM costs or also backup, monitoring, etc.?
   - Do we show monthly, annual, or lifetime costs?

## Success Criteria

- [ ] User can submit VM request via API/kubectl
- [ ] System automatically determines approval requirements
- [ ] Approvers receive notification with all relevant details
- [ ] Approvers can approve/reject via simple interface (REST API)
- [ ] Approved requests provision automatically
- [ ] Rejected requests notify requester with reason
- [ ] Complete audit trail in K8s events, Datadog, and Grafana dashboards
- [ ] Policy engine validates all requests (Kyverno or OPA)
- [ ] Auto-remediation (add missing platform tags)
- [ ] Integration with TargetProcess for ticket tracking
- [ ] Timeout handling (24h default)
- [ ] Support for multiple approval stages
- [ ] Cost estimation shown to approvers

## Next Steps

### Phase 1: Design & Decision (Current)
1. **Design Review** - Review this document and finalize decisions:
   - ✅ Choose policy engine: **Kyverno** (simple) vs **OPA** (complex) vs **Both** (hybrid)
   - ✅ Notification channels: Slack primary, Teams secondary
   - ✅ ITSM integration: TargetProcess (optional for dev/test, mandatory for prod)
   - ✅ Audit: Datadog + Grafana dashboards

### Phase 2: Policy Foundation (1-3 days)
2. **Install Kyverno** (if chosen):
   ```bash
   helm install kyverno kyverno/kyverno -n kyverno --create-namespace
   helm install policy-reporter kyverno/policy-reporter -n kyverno
   ```
3. **Create Validation Policies** - Basic tag requirements, naming conventions:
   - `helm/vela/policies/kyverno/require-vm-tags.yaml`
   - `helm/vela/policies/kyverno/enforce-naming.yaml`
   - `helm/vela/policies/kyverno/add-platform-tags.yaml` (mutation)
4. **Test Policy Enforcement** - Apply invalid Application, verify rejection

### Phase 3: Basic Approval Workflow (2-3 days)
5. **Prototype Workflow** - Simple suspend/resume with manual approval:
   - Create Application with workflow steps
   - Test `vela workflow suspend` and `vela workflow resume`
   - Verify workflow state transitions
6. **Slack Notification** - Webhook integration for approval requests:
   - Create incoming webhook in Slack workspace
   - Add notification step to workflow
   - Test approval notification with Block Kit message
7. **Teams Notification** - Secondary channel with adaptive cards:
   - Create webhook connector in Teams channel
   - Duplicate notification step for Teams
   - Test multi-channel notifications

### Phase 4: Approval API (3-5 days)
8. **REST API Endpoints** - Kubernetes API proxy for approve/reject:
   - Document K8s API paths for workflow operations
   - Create ServiceAccount with workflow management permissions
   - Test approval via `curl` commands
9. **Cost Estimation Logic** - Calculate monthly VM + trait costs:
   - Create cost calculation step (CUE or external service)
   - Display in notification messages
   - Add budget threshold checks

### Phase 5: Advanced Features (1-2 weeks)
10. **Multi-Stage Workflow** - Sequential approval chains:
    - Team lead approval → Finance approval
    - ConfigMap for approval matrix
    - Test approval ordering
11. **TargetProcess Integration** - Link workflows to tickets:
    - TP REST API authentication
    - Create/update ticket step
    - Webhook receiver for TP → KubeVela sync
12. **OPA Integration** (if hybrid approach) - Complex approval logic:
    - Install OPA Gatekeeper
    - Create approval routing policies (Rego)
    - Test auto-approve vs manual approval paths
13. **Emergency Bypass** - Break-glass mechanism:
    - Create approver-override RBAC role
    - Add bypass annotation support
    - Audit bypass events to Datadog

### Phase 6: Monitoring & Production (1 week)
14. **Datadog + Grafana Dashboards**:
    - Approval SLA metrics (time to approve)
    - Approver activity (who approves what)
    - Policy violation trends
    - Cost estimates vs actuals
15. **UI Integration** - ops-box platform:
    - Show pending approvals
    - Approval status badges
    - Real-time workflow state
16. **Documentation** - Complete Demo 07:
    - Architecture diagrams
    - Policy examples (Kyverno + OPA)
    - API usage examples
    - Troubleshooting guide
17. **Testing** - Validate all scenarios:
    - Happy path: auto-approve small dev VM
    - Approval path: large prod VM with multi-stage
    - Rejection path: VM without required tags
    - Timeout path: approval expires after 24h
    - Bypass path: emergency override with audit

## References

**KubeVela**:
- [KubeVela Workflow](https://kubevela.io/docs/end-user/workflow/overview)
- [Workflow Suspend Step](https://kubevela.io/docs/end-user/workflow/built-in-workflow-defs#suspend)
- [Notification Step](https://kubevela.io/docs/end-user/workflow/built-in-workflow-defs#notification)
- [CUE Operations](https://kubevela.io/docs/platform-engineers/workflow/cue-actions)

**Kyverno**:
- [Kyverno Documentation](https://kyverno.io/docs/)
- [Policy Examples](https://kyverno.io/policies/)
- [Kyverno CLI](https://kyverno.io/docs/kyverno-cli/)
- [Policy Reporter](https://github.com/kyverno/policy-reporter)

**OPA**:
- [OPA Documentation](https://www.openpolicyagent.org/docs/latest/)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/docs/)
- [Rego Playground](https://play.openpolicyagent.org/)

**Integrations**:
- [Slack Block Kit](https://api.slack.com/block-kit)
- [Teams Adaptive Cards](https://learn.microsoft.com/en-us/adaptive-cards/)
- [TargetProcess API](https://dev.targetprocess.com/docs/api)

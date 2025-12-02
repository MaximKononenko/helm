#!/bin/bash
#
# Import Existing Azure VM into KubeVela Management
# 
# This script demonstrates how to adopt existing Azure VMs without recreation.
# Similar to "terraform import" but with automatic configuration generation.
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Azure VM Import Demo - Adopt Without Recreation          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo

# Check prerequisites
echo -e "${YELLOW}[1/6] Checking prerequisites...${NC}"

if ! command -v asoctl &> /dev/null; then
    echo -e "${RED}Error: asoctl not found. Installing...${NC}"
    curl -L https://github.com/Azure/azure-service-operator/releases/latest/download/asoctl-linux-amd64.gz -o /tmp/asoctl.gz
    gunzip /tmp/asoctl.gz
    sudo install -o root -g root -m 0755 /tmp/asoctl /usr/local/bin/asoctl
    echo -e "${GREEN}✓ asoctl installed${NC}"
else
    echo -e "${GREEN}✓ asoctl found${NC}"
fi

if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Azure CLI found${NC}"

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ kubectl found${NC}"

# Configuration (update these for your environment)
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-existing-vms}"
VM_NAME="${VM_NAME:-existing-vm-01}"
NAMESPACE="${NAMESPACE:-azureserviceoperator-system}"

echo
echo -e "${YELLOW}Configuration:${NC}"
echo -e "  Resource Group: ${GREEN}$RESOURCE_GROUP${NC}"
echo -e "  VM Name: ${GREEN}$VM_NAME${NC}"
echo -e "  Namespace: ${GREEN}$NAMESPACE${NC}"
echo

# Get VM ARM ID
echo -e "${YELLOW}[2/6] Retrieving VM ARM ID...${NC}"
VM_ARM_ID=$(az vm show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --query id -o tsv 2>/dev/null || echo "")

if [ -z "$VM_ARM_ID" ]; then
    echo -e "${RED}Error: VM '$VM_NAME' not found in resource group '$RESOURCE_GROUP'${NC}"
    echo -e "${YELLOW}Available VMs:${NC}"
    az vm list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name, Location:location}" -o table
    exit 1
fi

echo -e "${GREEN}✓ Found VM: $VM_ARM_ID${NC}"

# Show VM current state
echo
echo -e "${YELLOW}[3/6] Current VM configuration:${NC}"
az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" \
  --query "{Name:name, Size:hardwareProfile.vmSize, Location:location, ProvisioningState:provisioningState, Tags:tags}" \
  -o json | jq .

# Import VM configuration using asoctl
echo
echo -e "${YELLOW}[4/6] Importing VM configuration...${NC}"
OUTPUT_FILE="imported-${VM_NAME}.yaml"

asoctl import azure-resource "$VM_ARM_ID" \
  --output "$OUTPUT_FILE" \
  --namespace "$NAMESPACE" \
  --annotation "serviceoperator.azure.com/reconcile-policy=detach-on-delete" \
  --annotation "imported-at=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --label "managed-by=kubevela" \
  --label "imported=true" \
  --verbose

echo -e "${GREEN}✓ Configuration exported to: $OUTPUT_FILE${NC}"

# Show what was imported
echo
echo -e "${YELLOW}[5/6] Imported resources:${NC}"
yq eval '.kind + "/" + .metadata.name' "$OUTPUT_FILE" | sed 's/^/  - /'

# Apply to cluster
echo
echo -e "${YELLOW}[6/6] Applying to Kubernetes...${NC}"
echo -e "${BLUE}Note: This will NOT recreate the VM, only adopt it for management${NC}"
echo

read -p "Apply to cluster? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Skipping apply. You can manually apply with:${NC}"
    echo -e "  kubectl apply -f $OUTPUT_FILE"
    exit 0
fi

kubectl apply -f "$OUTPUT_FILE"

# Wait for resources to be ready
echo
echo -e "${YELLOW}Waiting for resources to be ready...${NC}"
sleep 5

# Check VM status
VM_READY=$(kubectl get virtualmachine.compute.azure.com "$VM_NAME" -n "$NAMESPACE" \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")

if [ "$VM_READY" == "True" ]; then
    echo -e "${GREEN}✓ VM successfully adopted!${NC}"
else
    echo -e "${YELLOW}⚠ VM status: $VM_READY${NC}"
    echo -e "${YELLOW}Check status with:${NC}"
    echo -e "  kubectl describe virtualmachine.compute.azure.com $VM_NAME -n $NAMESPACE"
fi

# Verify no changes in Azure
echo
echo -e "${YELLOW}Verifying Azure state (should be unchanged)...${NC}"
PROVISION_STATE=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" \
  --query provisioningState -o tsv)
echo -e "  Provisioning State: ${GREEN}$PROVISION_STATE${NC}"

# Summary
echo
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  Import Complete!                          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${YELLOW}What happened:${NC}"
echo -e "  1. Existing VM configuration was exported from Azure"
echo -e "  2. ASO resources were created in Kubernetes"
echo -e "  3. ASO adopted the existing VM (no recreation)"
echo -e "  4. VM is now managed via Kubernetes/KubeVela"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  • View resources: kubectl get virtualmachine.compute.azure.com -n $NAMESPACE"
echo -e "  • Add traits: Apply backup-policy, monitoring, etc."
echo -e "  • Convert to ComponentDefinition: Use azure-vm type for easier management"
echo -e "  • Test updates: Modify tags, verify changes sync to Azure"
echo
echo -e "${BLUE}Reconcile Policy: detach-on-delete${NC}"
echo -e "  Deleting the Kubernetes resource will NOT delete the Azure VM"
echo -e "  To change this, remove the annotation and reapply"
echo

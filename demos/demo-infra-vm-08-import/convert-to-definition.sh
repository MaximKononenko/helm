#!/bin/bash
#
# Convert Imported VM to use ComponentDefinition
#
# This script shows how to transition from raw ASO resources (imported)
# to using our azure-vm ComponentDefinition for easier management.
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Convert Imported VM to ComponentDefinition               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo

IMPORTED_FILE="${1:-imported-existing-vm-01.yaml}"
OUTPUT_FILE="vm-with-definition.yaml"

if [ ! -f "$IMPORTED_FILE" ]; then
    echo -e "${RED}Error: Import file not found: $IMPORTED_FILE${NC}"
    echo -e "${YELLOW}Usage: $0 <imported-file.yaml>${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/4] Analyzing imported configuration...${NC}"

# Extract VM configuration
VM_NAME=$(yq eval 'select(.kind == "VirtualMachine") | .metadata.name' "$IMPORTED_FILE")
VM_SIZE=$(yq eval 'select(.kind == "VirtualMachine") | .spec.hardwareProfile.vmSize' "$IMPORTED_FILE")
LOCATION=$(yq eval 'select(.kind == "VirtualMachine") | .spec.location' "$IMPORTED_FILE")
DISK_SIZE=$(yq eval 'select(.kind == "VirtualMachine") | .spec.storageProfile.osDisk.diskSizeGB' "$IMPORTED_FILE")
STORAGE_TYPE=$(yq eval 'select(.kind == "VirtualMachine") | .spec.storageProfile.osDisk.managedDisk.storageAccountType' "$IMPORTED_FILE")
IMAGE_PUBLISHER=$(yq eval 'select(.kind == "VirtualMachine") | .spec.storageProfile.imageReference.publisher' "$IMPORTED_FILE")
IMAGE_OFFER=$(yq eval 'select(.kind == "VirtualMachine") | .spec.storageProfile.imageReference.offer' "$IMPORTED_FILE")
IMAGE_SKU=$(yq eval 'select(.kind == "VirtualMachine") | .spec.storageProfile.imageReference.sku' "$IMPORTED_FILE")
RESOURCE_GROUP=$(yq eval 'select(.kind == "VirtualMachine") | .spec.owner.armId' "$IMPORTED_FILE" | sed 's|.*/resourceGroups/\([^/]*\).*|\1|')
SUBSCRIPTION_ID=$(yq eval 'select(.kind == "VirtualMachine") | .spec.owner.armId' "$IMPORTED_FILE" | sed 's|.*/subscriptions/\([^/]*\)/.*|\1|')

# Extract network configuration
VNET_ARM_ID=$(yq eval 'select(.kind == "NetworkInterface") | .spec.ipConfigurations[0].subnet.reference.armId' "$IMPORTED_FILE")
VNET_RG=$(echo "$VNET_ARM_ID" | sed 's|.*/resourceGroups/\([^/]*\)/.*|\1|')
VNET_NAME=$(echo "$VNET_ARM_ID" | sed 's|.*/virtualNetworks/\([^/]*\)/.*|\1|')
SUBNET_NAME=$(echo "$VNET_ARM_ID" | sed 's|.*/subnets/\([^/]*\).*|\1|')

# Check for data disks
DATA_DISKS=$(yq eval 'select(.kind == "VirtualMachine") | .spec.storageProfile.dataDisks // []' "$IMPORTED_FILE")
HAS_DATA_DISKS=$(echo "$DATA_DISKS" | yq eval 'length > 0')

echo -e "${GREEN}✓ Extracted configuration:${NC}"
echo -e "  VM Name: ${BLUE}$VM_NAME${NC}"
echo -e "  Size: ${BLUE}$VM_SIZE${NC}"
echo -e "  Location: ${BLUE}$LOCATION${NC}"
echo -e "  OS Disk: ${BLUE}${DISK_SIZE}GB ${STORAGE_TYPE}${NC}"
echo -e "  Image: ${BLUE}${IMAGE_PUBLISHER}:${IMAGE_OFFER}:${IMAGE_SKU}${NC}"
echo -e "  Network: ${BLUE}${VNET_NAME}/${SUBNET_NAME}${NC}"
[ "$HAS_DATA_DISKS" == "true" ] && echo -e "  Data Disks: ${BLUE}Yes${NC}"

# Map Azure VM size to our friendly sizes
echo
echo -e "${YELLOW}[2/4] Mapping VM size...${NC}"

case "$VM_SIZE" in
    Standard_B1s|Standard_B2s)
        FRIENDLY_SIZE="small"
        ;;
    Standard_D2s_v3|Standard_B2ms)
        FRIENDLY_SIZE="medium"
        ;;
    Standard_D4s_v3|Standard_D4as_v4)
        FRIENDLY_SIZE="large"
        ;;
    *)
        FRIENDLY_SIZE="medium"
        echo -e "${YELLOW}⚠ Unknown size $VM_SIZE, using 'medium'${NC}"
        ;;
esac

echo -e "${GREEN}✓ Mapped $VM_SIZE → $FRIENDLY_SIZE${NC}"

# Generate Application YAML using ComponentDefinition
echo
echo -e "${YELLOW}[3/4] Generating Application with ComponentDefinition...${NC}"

cat > "$OUTPUT_FILE" <<EOF
apiVersion: core.oam.dev/v1beta1
kind: Application
metadata:
  name: $VM_NAME
  namespace: azureserviceoperator-system
  annotations:
    description: "Imported VM now managed via ComponentDefinition"
    imported-from: "azure"
    imported-at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
spec:
  components:
    - name: $VM_NAME
      type: azure-vm
      properties:
        # Azure configuration
        subscriptionId: "$SUBSCRIPTION_ID"
        resourceGroup: "$RESOURCE_GROUP"
        vmName: "$VM_NAME"
        location: "$LOCATION"
        
        # VM sizing (user-friendly)
        vmSize: "$FRIENDLY_SIZE"
        environment: "prod"  # Adjust as needed
        
        # Storage
        osDiskSizeGB: $DISK_SIZE
        storageAccountType: "$STORAGE_TYPE"
        
        # Image
        imageReference:
          publisher: "$IMAGE_PUBLISHER"
          offer: "$IMAGE_OFFER"
          sku: "$IMAGE_SKU"
          version: "latest"
        
        # Admin credentials (reference existing secret)
        adminUsername: "azureuser"
        adminPasswordSecret:
          name: "vm-admin-password"
          key: "password"
        
        # Network (brownfield)
        network:
          vnetResourceGroup: "$VNET_RG"
          vnetName: "$VNET_NAME"
          subnetName: "$SUBNET_NAME"
        
        # Public IP
        publicIP:
          enabled: false
        
        # Tags
        tags:
          ImportedFrom: "manual-creation"
          ManagedBy: "kubevela"
          ConvertedAt: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        
        # ASO credential
        credential:
          name: "aso-credential-catalina-vault-sqa"
          namespace: "azureserviceoperator-system"
EOF

# Add data disks if present
if [ "$HAS_DATA_DISKS" == "true" ]; then
    echo
    echo -e "${YELLOW}[3.5/4] Processing data disks...${NC}"
    
    # Extract data disk information and add to YAML
    yq eval 'select(.kind == "Disk") | .metadata.name' "$IMPORTED_FILE" | while read -r disk_name; do
        DISK_SIZE_GB=$(yq eval "select(.kind == \"Disk\" and .metadata.name == \"$disk_name\") | .spec.diskSizeGB" "$IMPORTED_FILE")
        DISK_TYPE=$(yq eval "select(.kind == \"Disk\" and .metadata.name == \"$disk_name\") | .spec.sku.name" "$IMPORTED_FILE")
        
        echo -e "  Found disk: ${BLUE}$disk_name${NC} (${DISK_SIZE_GB}GB, $DISK_TYPE)"
        
        # Append to dataDisks array in YAML
        cat >> "$OUTPUT_FILE" <<EOF
        dataDisks:
          - sizeGB: $DISK_SIZE_GB
            storageAccountType: "$DISK_TYPE"
            caching: "ReadWrite"
EOF
    done
fi

echo -e "${GREEN}✓ Application YAML generated: $OUTPUT_FILE${NC}"

# Show comparison
echo
echo -e "${YELLOW}[4/4] Comparison:${NC}"
echo
echo -e "${BLUE}Before (Raw ASO):${NC}"
echo -e "  - Multiple YAML documents (VM, NIC, Disks)"
echo -e "  - Manual resource coordination"
echo -e "  - Azure-specific SKU names"
echo
echo -e "${BLUE}After (ComponentDefinition):${NC}"
echo -e "  - Single Application resource"
echo -e "  - Automatic resource management"
echo -e "  - User-friendly size names (small/medium/large)"
echo -e "  - Trait support (backup, monitoring, cost-tracking)"
echo

# Summary
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Conversion Complete!                          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Review generated file: ${BLUE}$OUTPUT_FILE${NC}"
echo -e "  2. Delete old imported resources:"
echo -e "     ${BLUE}kubectl delete -f $IMPORTED_FILE${NC}"
echo -e "  3. Apply new Application:"
echo -e "     ${BLUE}kubectl apply -f $OUTPUT_FILE${NC}"
echo -e "  4. Add traits (optional):"
echo -e "     ${BLUE}kubectl edit application $VM_NAME -n azureserviceoperator-system${NC}"
echo
echo -e "${YELLOW}Benefits of ComponentDefinition:${NC}"
echo -e "  ✓ Simplified syntax"
echo -e "  ✓ Automatic resource coordination"
echo -e "  ✓ Environment-aware sizing"
echo -e "  ✓ Trait composition (backup, monitoring, security)"
echo -e "  ✓ Platform policy enforcement"
echo

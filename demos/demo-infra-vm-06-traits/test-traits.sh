#!/bin/bash
set -e

echo "=== Demo 6: Infrastructure Traits ==="
echo

# Get current directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "1. Applying TraitDefinitions..."
kubectl apply -f ../../vela/definitions/backup-policy-trait.yaml
kubectl apply -f ../../vela/definitions/cost-tracking-trait.yaml
kubectl apply -f ../../vela/definitions/security-baseline-trait.yaml
kubectl apply -f ../../vela/definitions/monitoring-trait.yaml

echo
echo "2. Verifying TraitDefinitions are available..."
kubectl get traitdefinition -n vela-system | grep -E "backup-policy|cost-tracking|security-baseline|monitoring"

echo
echo "3. Creating VM with all traits..."
kubectl apply -f vm-with-all-traits.yaml

echo
echo "4. Waiting 60 seconds for Application to be processed..."
sleep 60

echo
echo "5. Checking Application status..."
kubectl get application.core.oam.dev vm-with-traits -n azureserviceoperator-system

echo
echo "6. Checking generated ConfigMaps (trait outputs)..."
kubectl get configmap -n azureserviceoperator-system | grep vm-with-traits || echo "No ConfigMaps found yet (this is normal)"

echo
echo "7. Describing Application to see trait processing..."
kubectl describe application.core.oam.dev vm-with-traits -n azureserviceoperator-system | tail -20

echo
echo "8. Waiting 90 seconds for VM provisioning..."
sleep 90

echo
echo "9. Verifying VM in Azure with tags..."
az vm show \
  --resource-group rg-tst-eastus-istio-compute \
  --name vm-traits-demo-01 \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c \
  --query '{name:name, state:provisioningState, size:hardwareProfile.vmSize}' \
  -o table || echo "VM not yet provisioned (this is normal, may take 5-10 minutes)"

echo
echo "10. Checking tags (if VM exists)..."
az vm show \
  --resource-group rg-tst-eastus-istio-compute \
  --name vm-traits-demo-01 \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c \
  --query 'tags' \
  -o json 2>/dev/null || echo "VM not ready yet"

echo
echo "=== Expected Tags ==="
echo "From backup-policy trait:"
echo "  - BackupEnabled, BackupRetention, BackupSchedule, BackupVault"
echo
echo "From cost-tracking trait:"
echo "  - CostCenter, Department, Project, BillingCode, Approver"
echo
echo "From security-baseline trait:"
echo "  - SecurityLevel, ComplianceFramework, DataClassification, PatchingSchedule, SecurityContact"
echo
echo "From monitoring trait:"
echo "  - MonitoringEnabled, AlertSeverity, AlertContact, MetricsRetention, LogWorkspace"
echo
echo "From user properties:"
echo "  - Owner, Purpose"
echo
echo "From platform (ComponentDefinition):"
echo "  - ManagedBy, Environment"
echo

echo "=== Demo Complete ==="
echo
echo "Next steps:"
echo "  - Wait for VM to fully provision (5-10 minutes)"
echo "  - Check ConfigMaps: kubectl get configmap -n azureserviceoperator-system | grep vm-with-traits"
echo "  - View backup config: kubectl get configmap vm-with-traits-backup-config -n azureserviceoperator-system -o yaml"
echo "  - View security config: kubectl get configmap vm-with-traits-security-config -n azureserviceoperator-system -o yaml"
echo "  - View alert config: kubectl get configmap vm-with-traits-alert-config -n azureserviceoperator-system -o yaml"
echo "  - Cleanup: kubectl delete application.core.oam.dev vm-with-traits -n azureserviceoperator-system"

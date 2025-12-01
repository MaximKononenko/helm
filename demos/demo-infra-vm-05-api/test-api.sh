#!/bin/bash
# Demo 4: Infrastructure VM Provisioning via REST API
# This demonstrates how your UI would interact with the platform

set -e

NAMESPACE="azureserviceoperator-system"
APP_NAME="vm-api-test"

# Get API server and token
API_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
TOKEN=$(kubectl create token platform-api-test -n azureserviceoperator-system --duration=10m)

echo "=== Demo 4: REST API VM Provisioning ==="
echo "API Server: ${API_SERVER}"
echo ""

# 1. CREATE VM
echo "1. Creating VM via POST request..."
echo "POST ${API_SERVER}/apis/core.oam.dev/v1beta1/namespaces/${NAMESPACE}/applications"
curl -k -X POST \
  "${API_SERVER}/apis/core.oam.dev/v1beta1/namespaces/${NAMESPACE}/applications" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d @vm-create.json \
  | jq -r 'if .kind == "Application" then "✓ Application created: \(.metadata.name)" else . end'

echo -e "\n\n2. Waiting for VM to provision (45 seconds)..."
sleep 45

# 2. GET STATUS
echo -e "\n3. Getting Application status via GET request..."
echo "GET ${API_SERVER}/apis/core.oam.dev/v1beta1/namespaces/${NAMESPACE}/applications/${APP_NAME}"
curl -k -X GET \
  "${API_SERVER}/apis/core.oam.dev/v1beta1/namespaces/${NAMESPACE}/applications/${APP_NAME}" \
  -H "Authorization: Bearer ${TOKEN}" \
  | jq '{name: .metadata.name, phase: .status.workflow.phase, healthy: .status.services[0].healthy}'

# 3. VERIFY IN AZURE
echo -e "\n4. Verifying VM in Azure..."
az vm show \
  --resource-group rg-tst-eastus-istio-compute \
  --name vm-api-test-01 \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c \
  --query '{name:name, size:hardwareProfile.vmSize, state:provisioningState, tags:tags}' \
  -o json

# 4. UPDATE VM SIZE
echo -e "\n5. Updating VM size via PATCH request (small -> large)..."
echo "PATCH ${API_SERVER}/apis/core.oam.dev/v1beta1/namespaces/${NAMESPACE}/applications/${APP_NAME}"
curl -k -X PATCH \
  "${API_SERVER}/apis/core.oam.dev/v1beta1/namespaces/${NAMESPACE}/applications/${APP_NAME}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/merge-patch+json" \
  -d @vm-update.json \
  | jq -r 'if .kind == "Application" then "✓ Application updated" else . end'

echo -e "\n\n6. Waiting for resize (60 seconds)..."
sleep 60

# 5. VERIFY UPDATE
echo -e "\n7. Verifying updated VM size..."
az vm show \
  --resource-group rg-tst-eastus-istio-compute \
  --name vm-api-test-01 \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c \
  --query '{name:name, size:hardwareProfile.vmSize}' \
  -o table

# 6. DELETE VM
echo -e "\n8. Deleting VM via DELETE request..."
echo "DELETE ${API_SERVER}/apis/core.oam.dev/v1beta1/namespaces/${NAMESPACE}/applications/${APP_NAME}"
curl -k -X DELETE \
  "${API_SERVER}/apis/core.oam.dev/v1beta1/namespaces/${NAMESPACE}/applications/${APP_NAME}" \
  -H "Authorization: Bearer ${TOKEN}" \
  | jq -r 'if .kind == "Status" and .status == "Success" then "✓ Application deleted" else . end'

echo -e "\n\n9. Waiting for cleanup (30 seconds)..."
sleep 30

# 7. VERIFY CLEANUP
echo -e "\n10. Verifying VM deletion..."
az vm show \
  --resource-group rg-tst-eastus-istio-compute \
  --name vm-api-test-01 \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c 2>&1 | grep -i "notfound" && echo "✓ VM Deleted"

echo -e "\n11. Checking for orphaned disks..."
az disk list \
  --resource-group rg-tst-eastus-istio-compute \
  --subscription a50f971b-376d-4d05-ac33-1e9fcfb8f32c \
  --query '[].name' -o table || echo "✓ No orphaned disks"

echo -e "\n=== Demo Complete ==="

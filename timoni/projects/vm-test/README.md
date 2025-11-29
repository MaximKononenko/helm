# VM Test Project

This project tests the VM Timoni module deployment.

## Configuration

- **Subscription**: Catalina-Vault-SQA (a50f971b-376d-4d05-ac33-1e9fcfb8f32c)
- **Location**: East US
- **Resource Group**: rg-tst-eastus-istio-compute (existing)
- **VM Size**: Standard_B2s
- **Network**: Existing VNet (vn-np-eastus-10-166-54-0-24)

## Usage

### Test Build (dry-run)
```bash
timoni build vm-test oci://catalina.azurecr.io/vm-module:0.1.0 \
  -f values.cue \
  -n default
```

### Apply to Cluster
```bash
timoni apply vm-test oci://catalina.azurecr.io/vm-module:0.1.0 \
  -f values.cue \
  -n default \
  --wait
```

### Check Status
```bash
# Check Timoni instance
timoni status vm-test -n default

# Check ASO2 resources
kubectl get virtualmachines.compute.azure.com -n default
kubectl get networkinterfaces.network.azure.com -n default

# Check detailed status
kubectl describe virtualmachine vm-timoni-test-01 -n default
```

### Delete
```bash
timoni delete vm-test -n default --wait
```

## Authentication

Uses ASO2 secret `aso-credential-catalina-vault-sqa` in `azureserviceoperator-system` namespace with Service Principal credentials.

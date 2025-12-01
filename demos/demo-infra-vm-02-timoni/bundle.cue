bundle: {
	apiVersion: "v1alpha1"
	name:       "vm-test"
	instances: {
		"vm-test": {
			module: {
				url:     "oci://catalina.azurecr.io/vm-module"
				version: "0.1.8"
			}
			namespace: "azureserviceoperator-system"
			values: {
				subscriptionId: "a50f971b-376d-4d05-ac33-1e9fcfb8f32c"
				location:       "eastus"

				names: {
					resourceGroup:    "rg-tst-eastus-istio-compute"
					vm:               "vm-timoni-test-01"
					networkInterface: "vm-timoni-test-01-nic"
					publicIP:         "vm-timoni-test-01-pip"
				}

				tags: {
					Environment: "test"
					Project:     "timoni-poc"
					ManagedBy:   "timoni"
				}

				vm: {
					size:          "Standard_B2s"
					adminUsername: "azureuser"
					adminPasswordSecret: {
						name: "vm-admin-password"
						key:  "password"
					}
					osDiskSizeGB: 30
					imageReference: {
						publisher: "Canonical"
						offer:     "0001-com-ubuntu-server-jammy"
						sku:       "22_04-lts-gen2"
						version:   "latest"
					}
				}

				network: {
					vnetResourceGroup: "rg-np-eastus-dashboard"
					vnetName:          "vn-np-eastus-10-166-54-0-24"
					subnetName:        "sn-tst-eastus-istio-10-166-54-0-26-aks-b"
				}

				publicIP: {
					enabled: false
				}

				credential: {
					name:      "aso-credential-catalina-vault-sqa"
					namespace: "azureserviceoperator-system"
				}
			}
		}
	}
}

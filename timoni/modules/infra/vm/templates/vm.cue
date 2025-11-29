package templates

import (
	compute "compute.azure.com/virtualmachine/v1api20220301"
)

#VirtualMachine: compute.#VirtualMachine & {
	_config:    #Config
	apiVersion: "compute.azure.com/v1api20220301"
	kind:       "VirtualMachine"
	metadata: {
		name:      _config.names.vm
		namespace: _config.metadata.namespace
		annotations: {
			"serviceoperator.azure.com/credential-from": _config.credential.name
		}
	}
	spec: {
		azureName: _config.names.vm
		location:  _config.location
		owner: {
			armId: "/subscriptions/\(_config.subscriptionId)/resourceGroups/\(_config.names.resourceGroup)"
		}
		tags: _config.tags

		hardwareProfile: {
			vmSize: _config.vm.size
		}

		osProfile: {
			computerName:  _config.names.vm
			adminUsername: _config.vm.adminUsername
			adminPassword: {
				// Secret reference for admin password
				name: _config.vm.adminPasswordSecret.name
				key:  _config.vm.adminPasswordSecret.key
			}
			linuxConfiguration: {
				disablePasswordAuthentication: false
			}
		}

		storageProfile: {
			imageReference: {
				publisher: _config.vm.imageReference.publisher
				offer:     _config.vm.imageReference.offer
				sku:       _config.vm.imageReference.sku
				version:   _config.vm.imageReference.version
			}
			osDisk: {
				createOption: "FromImage"
				diskSizeGB:   _config.vm.osDiskSizeGB
				managedDisk: {
					storageAccountType: "Premium_LRS"
				}
			}
		}

		networkProfile: {
			networkInterfaces: [{
				reference: {
					group: "network.azure.com"
					kind:  "NetworkInterface"
					name:  _config.names.networkInterface
				}
			}]
		}

		operatorSpec: {}
	}
}

package templates

import (
	network "network.azure.com/networkinterface/v1api20240301"
)

#NetworkInterface: network.#NetworkInterface & {
	_config:    #Config
	apiVersion: "network.azure.com/v1api20240301"
	kind:       "NetworkInterface"
	metadata: {
		name:      _config.names.networkInterface
		namespace: _config.metadata.namespace
		annotations: {
			"serviceoperator.azure.com/credential-from": _config.credential.name
		}
	}
	spec: {
		azureName: _config.names.networkInterface
		location: _config.location
		owner: {
			armId: "/subscriptions/\(_config.subscriptionId)/resourceGroups/\(_config.names.resourceGroup)"
		}
		tags: _config.tags

		ipConfigurations: [{
			name: "ipconfig1"
			subnet: {
				reference: {
					armId: "/subscriptions/\(_config.subscriptionId)/resourceGroups/\(_config.network.vnetResourceGroup)/providers/Microsoft.Network/virtualNetworks/\(_config.network.vnetName)/subnets/\(_config.network.subnetName)"
				}
			}
			if _config.publicIP.enabled {
				publicIPAddress: {
					reference: {
						name: _config.names.publicIP
					}
				}
			}
		}]

		operatorSpec: {}
	}
}

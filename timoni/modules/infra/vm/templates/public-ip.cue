package templates

import (
	network "network.azure.com/publicipaddress/v1api20240301"
)

#PublicIPAddress: network.#PublicIPAddress & {
	_config:    #Config
	apiVersion: "network.azure.com/v1api20240301"
	kind:       "PublicIPAddress"
	metadata: {
		name:      _config.names.publicIP
		namespace: _config.metadata.namespace
	}
	spec: {
		azureName: _config.names.publicIP
		location: _config.location
		owner: {
			armId: "/subscriptions/\(_config.subscriptionId)/resourceGroups/\(_config.names.resourceGroup)"
		}
		tags: _config.tags

		publicIPAllocationMethod: "Static"
		sku: {
			name: _config.publicIP.sku
		}

		operatorSpec: {}
	}
}

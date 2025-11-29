package templates

import (
	network "network.azure.com/virtualnetwork/v1api20201101"
)

#VirtualNetwork: network.#VirtualNetwork & {
	_config:    #Config
	apiVersion: "network.azure.com/v1api20201101"
	kind:       "VirtualNetwork"
	metadata: {
		name:      _config.names.vnet
		namespace: "default"
	}
	spec: {
		location: _config.location
		tags:     _config.tags
		owner: {
			name: _config.names.networkResourceGroup
		}
		addressSpace: {
			addressPrefixes: [_config.network.cidr]
		}
	}
}

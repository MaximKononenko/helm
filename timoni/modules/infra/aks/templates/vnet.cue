package templates

import (
	network "network.azure.com/virtualnetwork/v1api20201101"
)

#VirtualNetwork: network.#VirtualNetwork & {
	_config:    #Config
	apiVersion: "network.azure.com/v1api20201101"
	kind:       "VirtualNetwork"
	metadata: {
		name:      "\( _config.name )-vnet"
		namespace: "default"
	}
	spec: {
		location: _config.location
		owner: {
			name: _config.name // The Resource Group
		}
		addressSpace: {
			addressPrefixes: [_config.network.cidr]
		}
	}
}

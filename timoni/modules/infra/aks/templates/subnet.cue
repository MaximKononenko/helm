package templates

import (
	subnet "network.azure.com/virtualnetworkssubnet/v1api20201101"
)

#VirtualNetworksSubnet: subnet.#VirtualNetworksSubnet & {
	_config:    #Config
	apiVersion: "network.azure.com/v1api20201101"
	kind:       "VirtualNetworksSubnet"
	metadata: {
		name:      "aks-subnet"
		namespace: "default"
	}
	spec: {
		owner: {
			name: "\( _config.name )-vnet" // The VNet
		}
		addressPrefix: _config.network.subnetCidr
	}
}

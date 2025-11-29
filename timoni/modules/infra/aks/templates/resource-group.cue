package templates

import (
	resources "resources.azure.com/resourcegroup/v1api20200601"
)

#AKSResourceGroup: resources.#ResourceGroup & {
	_config:    #Config
	apiVersion: "resources.azure.com/v1api20200601"
	kind:       "ResourceGroup"
	metadata: {
		name:      _config.names.aksResourceGroup
		namespace: "default"
	}
	spec: {
		location: _config.location
		tags:     _config.tags
	}
}

#NetworkResourceGroup: resources.#ResourceGroup & {
	_config:    #Config
	apiVersion: "resources.azure.com/v1api20200601"
	kind:       "ResourceGroup"
	metadata: {
		name:      _config.names.networkResourceGroup
		namespace: "default"
	}
	spec: {
		location: _config.location
		tags:     _config.tags
	}
}

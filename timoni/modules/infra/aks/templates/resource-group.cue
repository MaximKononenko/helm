package templates

import (
	resources "resources.azure.com/resourcegroup/v1api20200601"
)

#ResourceGroup: resources.#ResourceGroup & {
	_config:    #Config
	apiVersion: "resources.azure.com/v1api20200601"
	kind:       "ResourceGroup"
	metadata: {
		name:      _config.name
		namespace: "default"
	}
	spec: {
		location: _config.location
	}
}

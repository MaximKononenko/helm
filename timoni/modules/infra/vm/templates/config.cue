package templates

// Config defines the schema for values.
#Config: {
	// Metadata injected by Timoni at runtime
	metadata: {
		name:      string
		namespace: string
	}
	moduleVersion: string
	kubeVersion:   string

	subscriptionId: string
	location:       string

	names: {
		resourceGroup:    string
		vm:               string
		networkInterface: string
		publicIP?:        string
	}

	tags: {[string]: string}

	vm: {
		size:          string
		adminUsername: string
		adminPasswordSecret: {
			name: string
			key:  string
		}
		osDiskSizeGB: int
		imageReference: {
			publisher: string
			offer:     string
			sku:       string
			version:   string
		}
	}

	network: {
		vnetResourceGroup: string
		vnetName:          string
		subnetName:        string
	}

	publicIP: {
		enabled: bool
		sku:     string
	}

	credential: {
		name:      string
		namespace: string
	}
}

// Instance defines the module output
#Instance: {
	config: #Config

	objects: {
		vm:               #VirtualMachine & {_config:      config}
		networkInterface: #NetworkInterface & {_config:    config}
		if config.publicIP.enabled {
			publicIP: #PublicIPAddress & {_config: config}
		}
	}
}

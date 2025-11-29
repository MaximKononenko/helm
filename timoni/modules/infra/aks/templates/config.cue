package templates

// Config defines the schema for the module values
#Config: {
	// Metadata (injected by Timoni)
	metadata: {
		name:      string
		namespace: string
	}
	
	// Module Version (injected by Timoni)
	moduleVersion: string
	// Kubernetes Version (injected by Timoni)
	kubeVersion: string

	// User-supplied values
	subscriptionId: string
	location: string
	
	names: {
		aksResourceGroup:     string
		networkResourceGroup: string
		aksCluster:           string
		vnet:                 string
	}

	tags: { [string]: string }

	network: {
		cidr: string
		subnetCidr: string
		podCidr: string
		serviceCidr: string
		dnsServiceIP: string
	}
	
	peering: {
		enabled: bool
		remoteVnetId: string
		remoteVnetName: string
	}

	cluster: {
		kubernetesVersion: string
		dnsPrefix:         string
		sku: {
			name: string
			tier: string
		}
	}
	defaultNodePool: {
		name:    string
		vmSize:  string
		count:   int
		minCount: int
		maxCount: int
		mode:    string
	}
}

// Instance takes the config and outputs the Kubernetes objects
#Instance: {
	config: #Config

	objects: {
		aksResourceGroup: #AKSResourceGroup & {_config: config}
		if config.names.networkResourceGroup != config.names.aksResourceGroup {
			networkResourceGroup: #NetworkResourceGroup & {_config: config}
		}
		vnet:          #VirtualNetwork & {_config: config}
		subnet:        #VirtualNetworksSubnet & {_config: config}
		aks:           #ManagedCluster & {_config: config}
	}
}

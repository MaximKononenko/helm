values: {
	subscriptionId: "00000000-0000-0000-0000-000000000000"
	name: "my-poc-cluster"
	location: "eastus2"
	network: {
		cidr: "10.100.0.0/16"
		subnetCidr: "10.100.0.0/24"
	}
	cluster: {
		kubernetesVersion: "1.29.0"
		dnsPrefix: "catmktg.com"
		sku: {
			name: "Base"
			tier: "Standard"
		}
	}
	defaultNodePool: {
		name: "systempool"
		vmSize: "Standard_DS2_v2"
		count: 2
		minCount: 1
		maxCount: 5
		mode: "System"
	}
}

package templates

import (
	containerservice "containerservice.azure.com/managedcluster/v1api20231001"
)

#ManagedCluster: containerservice.#ManagedCluster & {
	_config:    #Config
	apiVersion: "containerservice.azure.com/v1api20231001"
	kind:       "ManagedCluster"
	metadata: {
		name:      "\( _config.name )-aks"
		namespace: "default"
	}
	spec: {
		location: _config.location
		owner: {
			name: _config.name // The Resource Group
		}
		dnsPrefix: _config.cluster.dnsPrefix
		kubernetesVersion: _config.cluster.kubernetesVersion
		sku: _config.cluster.sku
		
		// Network Profile for Private Cluster
		networkProfile: {
			networkPlugin: "azure"
			networkPluginMode: "overlay"
			podCidr: _config.network.podCidr
			serviceCidr:   _config.network.serviceCidr
			dnsServiceIP:  _config.network.dnsServiceIP
			outboundType: "loadBalancer"
		}

		// API Server Access (Private)
		apiServerAccessProfile: {
			enablePrivateCluster: true
		}

		// Default Node Pool (Agent Pool)
		agentPoolProfiles: [{
			name:   _config.defaultNodePool.name
			count:  _config.defaultNodePool.count
			vmSize: _config.defaultNodePool.vmSize
			osType: "Linux"
			mode:   _config.defaultNodePool.mode
			vnetSubnetReference: {
				// Reference to the Subnet created in subnet.cue
				name: "aks-subnet"
				group: "network.azure.com"
				kind: "VirtualNetworksSubnet"
			}
		}]
	}
}

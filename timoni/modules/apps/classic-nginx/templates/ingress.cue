package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#Ingress: networkingv1.#Ingress & {
	#config: #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata:   #config.metadata
	if #config.ingress.annotations != _|_ {
		metadata: annotations: #config.ingress.annotations
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingress.className != _|_ {
			ingressClassName: #config.ingress.className
		}
		if #config.ingress.tls != _|_ {
			tls: #config.ingress.tls
		}
		rules: [
			for h in #config.ingress.hosts {
				host: h.host
				http: paths: [
					for p in h.paths {
						path:     p.path
						pathType: p.pathType
						backend: service: {
							name: #config.metadata.name
							port: number: #config.service.port
						}
					},
				]
			},
		]
	}
}

package templates

import (
    networkingv1 "k8s.io/api/networking/v1"
)

#Ingress: networkingv1.#Ingress & {
    #config:    #Config
    apiVersion: "networking.k8s.io/v1"
    kind:       "Ingress"
    metadata:   #config.metadata
    if #config.ingress.annotations != _|_ {
        metadata: annotations: #config.ingress.annotations
    }
    spec: networkingv1.#IngressSpec & {
        if #config.ingress.hosts != _|_ {
            rules: [
                for _, hostConfig in #config.ingress.hosts {
                    host: hostConfig.host
                    http: paths: [
                        for _, pathConfig in hostConfig.paths {
                            path:     pathConfig.path
                            pathType: pathConfig.pathType
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
}
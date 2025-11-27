package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config:    #Config
	#cmName:    string
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #config.metadata
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.replicas
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName: #config.metadata.name
				containers: [
					{
						name:            #config.metadata.name
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						ports: [
							{
								name:          "http"
								containerPort: #config.containerPort
								protocol:      "TCP"
							},
						]
						livenessProbe: {
							httpGet: {
								path: #config.probes.liveness.path
								port: #config.probes.liveness.port
							}
							if #config.probes.liveness.initialDelaySeconds != _|_ {
								initialDelaySeconds: #config.probes.liveness.initialDelaySeconds
							}
							if #config.probes.liveness.periodSeconds != _|_ {
								periodSeconds: #config.probes.liveness.periodSeconds
							}
						}
						readinessProbe: {
							httpGet: {
								path: #config.probes.readiness.path
								port: #config.probes.readiness.port
							}
							if #config.probes.readiness.initialDelaySeconds != _|_ {
								initialDelaySeconds: #config.probes.readiness.initialDelaySeconds
							}
							if #config.probes.readiness.periodSeconds != _|_ {
								periodSeconds: #config.probes.readiness.periodSeconds
							}
						}
						volumeMounts: [
							{
								mountPath: "/etc/nginx/conf.d"
								name:      "config"
							},
							if #config.mountIndexHtml {
								{
									mountPath: "/usr/share/nginx/html"
									name:      "html"
								}
							},
						]
						resources:       #config.resources
						securityContext: #config.securityContext
					},
				]
				volumes: [
					{
						name: "config"
						configMap: {
							name: #cmName
							items: [{
								key:  "default.conf"
								path: key
							}]
						}
					},
					if #config.mountIndexHtml {
						{
							name: "html"
							configMap: {
								name: #cmName
								items: [{
									key:  "index.html"
									path: key
								}]
							}
						}
					},
				]
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				if #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
			}
		}
	}
}

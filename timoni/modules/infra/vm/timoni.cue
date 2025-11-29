package main

import (
	templates "timoni.sh/vm/templates"
)

// Define the schema for the user-supplied values.
values: templates.#Config

// Define how Timoni should build, validate and apply the Kubernetes resources.
timoni: {
	apiVersion: "v1alpha1"

	// Define the instance that outputs the Kubernetes resources.
	instance: templates.#Instance & {
		// The user-supplied values are merged with defaults at runtime.
		config: values
		// These values are injected at runtime by Timoni.
		config: {
			metadata: {
				name:      string @tag(name)
				namespace: string @tag(namespace)
			}
			moduleVersion: string @tag(mv, var=moduleVersion)
			kubeVersion:   string @tag(kv, var=kubeVersion)
		}
	}

	// Pass Kubernetes resources outputted by the instance to Timoni's apply.
	apply: app: [for obj in instance.objects {obj}]
}

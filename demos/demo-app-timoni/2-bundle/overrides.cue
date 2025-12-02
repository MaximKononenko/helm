global: image: tag: "demo-app-01.187695"

bundle: {
	instances: {
		"demo-app-01-frontend": {
			values: {
				replicas: 2
			}
		}
	}
}

bundle: {
	instances: {
		"demo-app-01-backend": {
			values: {
				image: tag: "demo-app-01.187695"
			}
		}
		"demo-app-01-frontend": {
			values: {
				image: tag: "demo-app-01.187695"
				replicas: 2
			}
		}
	}
}

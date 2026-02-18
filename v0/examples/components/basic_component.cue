package components

import (
	core "opmodel.dev/core@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
	storage_resources "opmodel.dev/resources/storage@v0"
	workload_traits "opmodel.dev/traits/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// Basic Component Example
//// Demonstrates simple component composition with resources and traits
/////////////////////////////////////////////////////////////////

basicComponent: core.#Component & {
	metadata: {
		name: "basic-component"
		labels: {
			"core.opmodel.dev/workload-type": "stateless"
		}
	}

	// Compose resources and traits using helpers
	workload_resources.#Container
	storage_resources.#Volumes
	workload_traits.#Scaling

	// Compose resources and traits, providing concrete values for the spec.
	spec: {
		scaling: count: int | *1
		container: {
			name:            "nginx-container"
			image:           string | *"nginx:latest"
			imagePullPolicy: "IfNotPresent"
			ports: http: {
				name:       "http"
				targetPort: 80
				protocol:   "TCP"
			}
			env: {
				ENVIRONMENT: {
					name:  "ENVIRONMENT"
					value: "production"
				}
			}
			resources: {
				cpu: {
					request: "250m"
					limit:   "500m"
				}
				memory: {
					request: "128Mi"
					limit:   "256Mi"
				}
			}
		}
		volumes: dbData: {
			name: "dbData"
			persistentClaim: {
				size:         "10Gi"
				accessMode:   "ReadWriteOnce"
				storageClass: "standard"
			}
		}
	}
}

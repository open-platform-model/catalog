package components

import (
	core "opm.dev/core@v0"
	workload_resources "opm.dev/resources/workload@v0"
	storage_resources "opm.dev/resources/storage@v0"
	workload_traits "opm.dev/traits/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// Basic Component Example
//// Demonstrates simple component composition with resources and traits
/////////////////////////////////////////////////////////////////

basicComponent: core.#Component & {
	metadata: {
		name: "basic-component"
		labels: {
			"core.opm.dev/workload-type": "stateless"
		}
	}

	// Compose resources and traits using helpers
	workload_resources.#Container
	storage_resources.#Volumes
	workload_traits.#Replicas

	// Compose resources and traits, providing concrete values for the spec.
	spec: {
		replicas: int | *1
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
				limits: {
					cpu:    "500m"
					memory: "256Mi"
				}
				requests: {
					cpu:    "250m"
					memory: "128Mi"
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


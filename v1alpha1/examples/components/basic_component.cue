package components

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	workload_resources "opmodel.dev/resources/workload@v1"
	storage_resources "opmodel.dev/resources/storage@v1"
	workload_traits "opmodel.dev/traits/workload@v1"
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
		scaling: count: int
		container: schemas.#ContainerSchema & {
			name: "nginx-container"
			image: {
				repository: string | *"nginx"
				tag:        string | *"latest"
				digest:     string | *""
			}
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
				requests: {
					cpu:    "250m"
					memory: "128Mi"
				}
				limits: {
					cpu:    "500m"
					memory: "256Mi"
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

package components

import (
	core "opmodel.dev/core@v1"
	workload_resources "opmodel.dev/resources/workload@v1"
	storage_resources "opmodel.dev/resources/storage@v1"
	workload_traits "opmodel.dev/traits/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// Stateful Workload Example
/////////////////////////////////////////////////////////////////

statefulWorkload: core.#Component & {
	metadata: {
		name: "stateful-workload"
		labels: {
			"core.opmodel.dev/workload-type": "stateful"
		}
	}

	// Compose resources and traits using helpers
	workload_resources.#Container
	storage_resources.#Volumes
	workload_traits.#Scaling
	workload_traits.#RestartPolicy
	workload_traits.#UpdateStrategy
	workload_traits.#InitContainers

	spec: {
		scaling: count: int | *1
		restartPolicy: "Always"
		updateStrategy: {
			type: "RollingUpdate"
			rollingUpdate: {
				maxUnavailable: 1
				partition:      0
			}
		}
		initContainers: [{
			name: "init-db"
			image: {
				repository: string | *"postgres"
				tag:        string | *"14"
				digest:     string | *""
			}
			env: {
				PGHOST: {
					name:  "PGHOST"
					value: "localhost"
				}
			}
		}]
		container: {
			name: "postgres"
			image: {
				repository: string | *"postgres"
				tag:        string | *"14"
				digest:     string | *""
			}
			ports: {
				postgres: {
					name:       "postgres"
					targetPort: 5432
				}
			}
			env: {
				POSTGRES_DB: {
					name:  "POSTGRES_DB"
					value: "myapp"
				}
				POSTGRES_USER: {
					name:  "POSTGRES_USER"
					value: "admin"
				}
				POSTGRES_PASSWORD: {
					name:  "POSTGRES_PASSWORD"
					value: "secretpassword"
				}
			}
			livenessProbe: {
				exec: {
					command: ["pg_isready", "-U", "admin"]
				}
				initialDelaySeconds: 30
				periodSeconds:       10
				timeoutSeconds:      5
				failureThreshold:    3
			}
			readinessProbe: {
				exec: {
					command: ["pg_isready", "-U", "admin"]
				}
				initialDelaySeconds: 5
				periodSeconds:       10
				timeoutSeconds:      1
				failureThreshold:    3
			}
			resources: {
				requests: {
					cpu:    "500m"
					memory: "1Gi"
				}
				limits: {
					cpu:    "2000m"
					memory: "4Gi"
				}
			}
			volumeMounts: {
				data: {
					name:      "data"
					mountPath: "/var/lib/postgresql/data"
				}
			}
		}
		volumes: data: {
			name: "data"
			persistentClaim: {
				size: "10Gi"
			}
		}
	}
}

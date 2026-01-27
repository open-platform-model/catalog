package components

import (
	core "opm.dev/core@v0"
	workload_resources "opm.dev/resources/workload@v0"
	storage_resources "opm.dev/resources/storage@v0"
	workload_traits "opm.dev/traits/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// Database Components
/////////////////////////////////////////////////////////////////

mongodbComponent: core.#Component & {
	metadata: {
		name: "mongodb-component"
		labels: {
			"core.opm.dev/workload-type": "stateful"
		}
	}

	// Compose resources and traits using helpers
	workload_resources.#Container
	storage_resources.#Volumes
	workload_traits.#Replicas

	spec: {
		replicas: 1
		container: {
			name:  "mongodb"
			image: "mongo:6.0"
			ports: mongodb: {
				name:       "mongodb"
				targetPort: 27017
			}
			env: {
				MONGO_INITDB_ROOT_USERNAME: {
					name:  "MONGO_INITDB_ROOT_USERNAME"
					value: "admin"
				}
				MONGO_INITDB_ROOT_PASSWORD: {
					name:  "MONGO_INITDB_ROOT_PASSWORD"
					value: "mongopassword"
				}
				MONGO_INITDB_DATABASE: {
					name:  "MONGO_INITDB_DATABASE"
					value: "myapp"
				}
			}
			volumeMounts: {
				"mongo-data": {
					name:      "mongo-data"
					mountPath: "/data/db"
				}
			}
		}
		volumes: "mongo-data": {
			name: "mongo-data"
			persistentClaim: {
				size:         "50Gi"
				storageClass: "fast-ssd"
			}
		}
	}
}

postgresComponent: core.#Component & {
	metadata: {
		name: "postgres-component"
		labels: {
			"core.opm.dev/workload-type": "stateful"
		}
	}

	// Compose resources and traits using helpers
	workload_resources.#Container
	storage_resources.#Volumes
	workload_traits.#Replicas

	spec: {
		replicas: 1
		container: {
			name:  "postgres"
			image: string | *"postgres:14"
			ports: postgres: {
				name:       "postgres"
				targetPort: 5432
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
					value: "postgrespassword"
				}
			}
			volumeMounts: {
				"postgres-data": {
					name:      "postgres-data"
					mountPath: "/var/lib/postgresql/data"
				}
			}
		}
		volumes: "postgres-data": {
			name: "postgres-data"
			persistentClaim: {
				size: string | *"100Gi"
			}
		}
	}
}

redisComponent: core.#Component & {
	metadata: {
		name: "redis-component"
		labels: {
			"core.opm.dev/workload-type": "stateless"
		}
	}

	// Compose resources and traits using helpers
	workload_resources.#Container
	workload_traits.#Replicas

	spec: {
		replicas: 1
		container: {
			name:  "redis"
			image: "redis:7.0"
			ports: redis: {
				name:       "redis"
				targetPort: 6379
			}
		}
	}
}

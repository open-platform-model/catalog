package components

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	workload_resources "opmodel.dev/resources/workload@v1"
	storage_resources "opmodel.dev/resources/storage@v1"
	workload_traits "opmodel.dev/traits/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// Database Components
/////////////////////////////////////////////////////////////////

mongodbComponent: core.#Component & {
	metadata: {
		name: "mongodb-component"
		labels: {
			"core.opmodel.dev/workload-type": "stateful"
		}
	}

	// Compose resources and traits using helpers
	workload_resources.#Container
	storage_resources.#Volumes
	workload_traits.#Scaling

	_volumes: spec.volumes

	spec: {
		scaling: count: 1
		container: {
			name: "mongodb"
			image: {
				repository: "mongo"
				tag:        "6.0"
				digest:     ""
			}
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
				"mongo-data": schemas.#VolumeMountSchema & {
					mountPath: "/data/db"
				} & _volumes["mongo-data"]
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
			"core.opmodel.dev/workload-type": "stateful"
		}
	}

	// Compose resources and traits using helpers
	workload_resources.#Container
	storage_resources.#Volumes
	workload_traits.#Scaling

	_volumes: spec.volumes

	spec: {
		scaling: count: 1
		container: {
			name: "postgres"
			image: {
				repository: string | *"postgres"
				tag:        string | *"14"
				digest:     string | *""
			}
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
				"postgres-data": schemas.#VolumeMountSchema & {
					mountPath: "/var/lib/postgresql/data"
				} & _volumes["postgres-data"]
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
			"core.opmodel.dev/workload-type": "stateless"
		}
	}

	// Compose resources and traits using helpers
	workload_resources.#Container
	workload_traits.#Scaling

	spec: {
		scaling: count: 1
		container: {
			name: "redis"
			image: {
				repository: "redis"
				tag:        "7.0"
				digest:     ""
			}
			ports: redis: {
				name:       "redis"
				targetPort: 6379
			}
		}
	}
}

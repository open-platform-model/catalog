package components

import (
	core "opmodel.dev/core@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
	workload_traits "opmodel.dev/traits/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// Task Workload Example
/////////////////////////////////////////////////////////////////

taskWorkload: core.#Component & {
	metadata: {
		name: "task-workload"
		labels: {
			"core.opmodel.dev/workload-type": "task"
		}
	}

	// Compose resources and traits using helpers
	workload_resources.#Container
	workload_traits.#RestartPolicy
	workload_traits.#JobConfig
	workload_traits.#InitContainers

	spec: {
		restartPolicy: "OnFailure"
		jobConfig: {
			completions:             1
			parallelism:             1
			backoffLimit:            3
			activeDeadlineSeconds:   3600
			ttlSecondsAfterFinished: 86400
		}
		initContainers: [{
			name:  "pre-migration-check"
			image: string | *"myregistry.io/migrations:v2.0.0"
			env: {
				CHECK_MODE: {
					name:  "CHECK_MODE"
					value: "true"
				}
			}
		}]
		container: {
			name:            "migration"
			image:           string | *"myregistry.io/migrations:v2.0.0"
			imagePullPolicy: "IfNotPresent"
			env: {
				DATABASE_URL: {
					name:  "DATABASE_URL"
					value: "postgres://localhost:5432/myapp"
				}
				MIGRATION_VERSION: {
					name:  "MIGRATION_VERSION"
					value: "v2.0.0"
				}
			}
			resources: {
				requests: {
					cpu:    "500m"
					memory: "512Mi"
				}
				limits: {
					cpu:    "1000m"
					memory: "1Gi"
				}
			}
		}
	}
}

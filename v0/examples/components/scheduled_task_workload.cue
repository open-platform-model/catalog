package components

import (
	core "opmodel.dev/core@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
	workload_traits "opmodel.dev/traits/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// Scheduled Task Workload Example
/////////////////////////////////////////////////////////////////

scheduledTaskWorkload: core.#Component & {
	metadata: {
		name: "scheduled-task-workload"
		labels: {
			"core.opmodel.dev/workload-type": "scheduled-task"
		}
	}

	// Compose resources and traits using helpers
	workload_resources.#Container
	workload_traits.#RestartPolicy
	workload_traits.#CronJobConfig
	workload_traits.#InitContainers

	spec: {
		restartPolicy: "OnFailure"
		cronJobConfig: {
			scheduleCron:               "0 2 * * *"
			concurrencyPolicy:          "Forbid"
			startingDeadlineSeconds:    300
			successfulJobsHistoryLimit: 3
			failedJobsHistoryLimit:     1
		}
		initContainers: [{
			name:  "pre-backup-check"
			image: string | *"postgres:14"
			env: {
				PGHOST: {
					name:  "PGHOST"
					value: "postgres-service"
				}
			}
		}]
		container: {
			name:            "backup"
			image:           "postgres:14"
			imagePullPolicy: "IfNotPresent"
			env: {
				PGHOST: {
					name:  "PGHOST"
					value: "postgres-service"
				}
				PGUSER: {
					name:  "PGUSER"
					value: "admin"
				}
				PGPASSWORD: {
					name:  "PGPASSWORD"
					value: "secretpassword"
				}
				BACKUP_LOCATION: {
					name:  "BACKUP_LOCATION"
					value: "/backups"
				}
			}
			resources: {
				requests: {
					cpu:    "250m"
					memory: "256Mi"
				}
				limits: {
					cpu:    "500m"
					memory: "512Mi"
				}
			}
			volumeMounts: {
				backups: {
					name:      "backup-storage"
					mountPath: "/backups"
				}
			}
		}
	}
}

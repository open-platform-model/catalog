package components

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	workload_resources "opmodel.dev/resources/workload@v1"
	storage_resources "opmodel.dev/resources/storage@v1"
	workload_traits "opmodel.dev/traits/workload@v1"
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
	storage_resources.#Volumes
	workload_traits.#RestartPolicy
	workload_traits.#CronJobConfig
	workload_traits.#InitContainers

	_volumes: spec.volumes

	spec: {
		restartPolicy: "OnFailure"
		cronJobConfig: {
			scheduleCron:               string | *"0 0 * * *" // Default to daily at midnight
			concurrencyPolicy:          "Forbid"
			startingDeadlineSeconds:    300
			successfulJobsHistoryLimit: 3
			failedJobsHistoryLimit:     1
		}
		initContainers: [{
			name: "pre-backup-check"
			image: {
				repository: string | *"alpine"
				tag:        string | *"latest"
				digest:     string | *""
			}
			env: {
				PGHOST: {
					name:  "PGHOST"
					value: "postgres-service"
				}
			}
		}]
		container: {
			name: "backup"
			image: {
				repository: string | *"postgres-backup"
				tag:        string | *"latest"
				digest:     string | *""
			}
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
				backups: schemas.#VolumeMountSchema & {
					mountPath: "/backups"
				} & _volumes.backups
			}
		}
		volumes: {
			backups: {
				name: "backup-storage"
				persistentClaim: {
					size: "50Gi"
				}
			}
		}
	}
}

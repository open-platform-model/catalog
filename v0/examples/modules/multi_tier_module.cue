package modules

import (
	core "opmodel.dev/core@v0"
	components "opmodel.dev/examples/components@v0"
)

/////////////////////////////////////////////////////////////////
//// Multi-Tier Module Example
/////////////////////////////////////////////////////////////////

multiTierModule: core.#Module & {
	metadata: {
		apiVersion: "opmodel.dev@v0"
		name:       "multi-tier-module"
		version:    "0.1.0"
	}

	#components: {
		database: components.statefulWorkload & {
			spec: {
				replicas: #config.database.replicas
				container: image: #config.database.image
			}
		}
		logAgent: components.daemonWorkload & {
			spec: {
				container: image: #config.logAgent.image
			}
		}
		setupJob: components.taskWorkload & {
			spec: {
				container: image: #config.setupJob.image
			}
		}
		backupJob: components.scheduledTaskWorkload & {
			spec: {
				container: image:            #config.backupJob.image
				cronJobConfig: scheduleCron: #config.backupJob.schedule
			}
		}
	}

	#config: {
		database: {
			replicas: int
			image:    string
		}
		logAgent: {
			image: string
		}
		setupJob: {
			image: string
		}
		backupJob: {
			image:    string
			schedule: string
		}
	}

	values: {
		database: {
			replicas: 1
			image:    "postgres:14"
		}
		logAgent: {
			image: "prom/node-exporter:v1.6.1"
		}
		setupJob: {
			image: "myregistry.io/migrations:v2.0.0"
		}
		backupJob: {
			image:    "postgres:14"
			schedule: "0 2 * * *"
		}
	}
}

multiTierModuleRelease: core.#ModuleRelease & {
	metadata: {
		name:      "multi-tier-release"
		namespace: "default"
	}
	#module: multiTierModule
	values: {
		database: {
			replicas: 2
			image:    "postgres:14.5"
		}
		logAgent: {
			image: "prom/node-exporter:v1.7.0"
		}
		setupJob: {
			image: "myregistry.io/migrations:v2.1.0"
		}
		backupJob: {
			image:    "postgres:14.5"
			schedule: "0 3 * * *"
		}
	}
}

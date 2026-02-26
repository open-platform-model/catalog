package modules

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	components "opmodel.dev/examples/components@v1"
)

/////////////////////////////////////////////////////////////////
//// Multi-Tier Module Example
/////////////////////////////////////////////////////////////////

multiTierModule: core.#Module & {
	metadata: {
		modulePath: "opmodel.dev"
		name:          "multi-tier-module"
		version:       "0.1.0"
	}

	#components: {
		database: components.statefulWorkload & {
			spec: {
				scaling: count:   #config.database.scaling
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
			scaling: int
			image:   schemas.#Image
		}
		logAgent: {
			image: schemas.#Image
		}
		setupJob: {
			image: schemas.#Image
		}
		backupJob: {
			image:    schemas.#Image
			schedule: string
		}
	}

	debugValues: {
		database: {
			scaling: 1
			image: {
				repository: "postgres"
				tag:        "14"
				digest:     ""
			}
		}
		logAgent: {
			image: {
				repository: "prom/node-exporter"
				tag:        "v1.6.1"
				digest:     ""
			}
		}
		setupJob: {
			image: {
				repository: "myregistry.io/migrations"
				tag:        "v2.0.0"
				digest:     ""
			}
		}
		backupJob: {
			image: {
				repository: "postgres"
				tag:        "14"
				digest:     ""
			}
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
			scaling: 2
			image: {
				repository: "postgres"
				tag:        "14.5"
				digest:     ""
			}
		}
		logAgent: {
			image: {
				repository: "prom/node-exporter"
				tag:        "v1.7.0"
				digest:     ""
			}
		}
		setupJob: {
			image: {
				repository: "myregistry.io/migrations"
				tag:        "v2.1.0"
				digest:     ""
			}
		}
		backupJob: {
			image: {
				repository: "postgres"
				tag:        "14.5"
				digest:     ""
			}
			schedule: "0 3 * * *"
		}
	}
}

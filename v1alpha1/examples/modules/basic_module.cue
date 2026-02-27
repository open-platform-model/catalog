package modules

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	components "opmodel.dev/examples/components@v1"
)

/////////////////////////////////////////////////////////////////
//// Basic Module Example
/////////////////////////////////////////////////////////////////

basicModule: core.#Module & {
	metadata: {
		modulePath: "opmodel.dev"
		name:       "basic-module"
		version:    "0.1.0"

		defaultNamespace: "default"

		labels: {
			"example.opmodel.dev/module-type": "basic"
		}
	}

	#components: {
		web: components.basicComponent & {
			spec: {
				scaling: count: #config.web.replicas
				container: {
					image: #config.web.image
				}
			}
		}
		db: components.postgresComponent & {
			spec: {
				container: image: #config.db.image
				volumes: "postgres-data": {
					persistentClaim: size: #config.db.volumeSize
				}
			}
		}
	}

	#config: {
		web: {
			replicas: int | *1
			image: schemas.#Image & {
				repository: string | *"nginx"
				tag:        string | *"latest"
				digest:     string | *""
			}
		}
		db: {
			image: schemas.#Image & {
				repository: string | *"postgres"
				tag:        string | *"latest"
				digest:     string | *""
			}
			volumeSize: string | *"5Gi"
		}
	}

	debugValues: {
		web: {
			replicas: 1
			image: {
				repository: "nginx"
				tag:        "1.20.0"
				digest:     ""
			}
		}
		db: {
			image: {
				repository: "postgres"
				tag:        "14.0"
				digest:     ""
			}
			volumeSize: "5Gi"
		}
	}
}

basicModuleRelease: core.#ModuleRelease & {
	metadata: {
		name:      "basic-module-release"
		namespace: "production"

		labels: {
			"example.com/release-type": "basic"
		}
	}
	#module: basicModule
	values: {
		web: {
			replicas: 3
			image: {
				repository: "nginx"
				tag:        "1.21.6"
				digest:     ""
			}
		}
		db: {
			image: {
				repository: "postgres"
				tag:        "14.10"
				digest:     ""
			}
			volumeSize: "5Gi"
		}
	}
}

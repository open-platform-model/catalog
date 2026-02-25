package modules

import (
	core "opmodel.dev/core@v1"
	components "opmodel.dev/examples/components@v1"
)

/////////////////////////////////////////////////////////////////
//// Basic Module Example
/////////////////////////////////////////////////////////////////

basicModule: core.#Module & {
	metadata: {
		cueModulePath: "opmodel.dev@v1"
		name:          "basic-module"
		version:       "0.1.0"

		defaultNamespace: "default"

		labels: {
			"example.opmodel.dev/module-type": "basic"
		}
	}

	#components: {
		web: components.basicComponent & {
			spec: {
				scaling: count: #config.web.scaling
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
			scaling: int
			image:   string
		}
		db: {
			scaling:    int
			image:      string
			volumeSize: string
		}
	}

	debugValues: {
		web: {
			scaling: 1
			image:   "nginx:1.20.0"
		}
		db: {
			image:      "postgres:14.0"
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
			scaling: 3
			image:   "nginx:1.21.6"
		}
		db: {
			scaling:    2
			image:      "postgres:14.5"
			volumeSize: "10Gi"
		}
	}
}

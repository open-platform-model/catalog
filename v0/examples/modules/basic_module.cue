package modules

import (
	core "opmodel.dev/core@v0"
	components "opmodel.dev/examples/components@v0"
)

/////////////////////////////////////////////////////////////////
//// Basic Module Example
/////////////////////////////////////////////////////////////////

basicModule: core.#Module & {
	metadata: {
		apiVersion: "opmodel.dev@v0"
		name:       "BasicModule"
		version:    "0.1.0"

		defaultNamespace: "default"

		labels: {
			"example.com/module-type": "basic"
		}
	}

	#components: {
		web: components.basicComponent & {
			spec: {
				replicas: values.web.replicas
				container: {
					image: values.web.image
				}
			}
		}
		db:  components.postgresComponent & {
			spec: {
				container: {
					image: values.db.image
				}
				volumes: "postgres-data": {
					persistentClaim: {
						size: values.db.volumeSize
					}
				}
			}
		}
	}

	#spec: {
		web: {
			replicas: int
			image:    string
		}
		db: {
			image:      string
			volumeSize: string
		}
	}

	values: {
		web: {
			replicas: 1
			image:    "nginx:1.20.0"
		}
		db: {
			image:      "postgres:14.0"
			volumeSize: "5Gi"
		}
	}
}

basicModuleRelease: core.#ModuleRelease & {
	metadata: {
		name: "basic-module-release"
		namespace: "production"

		labels: {
			"example.com/release-type": "basic"
		}
	}
	#module: basicModule
	values: {
		web: {
			replicas: 3
			image:    "nginx:1.21.6"
		}
		db: {
			image:      "postgres:14.5"
			volumeSize: "10Gi"
		}
	}
}

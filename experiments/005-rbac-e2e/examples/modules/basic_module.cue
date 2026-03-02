package modules

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	components "opmodel.dev/examples/components@v1"
)

/////////////////////////////////////////////////////////////////
//// Basic Module Example
//// Demonstrates:
////   - #Secret fields in #config (auto-discovered at release time)
////   - Mixed fulfillment: #SecretLiteral + #SecretK8sRef
////   - env var wiring via from: (no manual spec.secrets bridging)
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
					// Env vars wired to secrets via from: — no manual spec.secrets needed.
					// At release time, #ModuleRelease auto-discovers these #Secret values
					// and generates the opm-secrets component automatically.
					env: {
						DB_PASSWORD: {
							name: "DB_PASSWORD"
							from: #config.db.password
						}
						DB_HOST: {
							name: "DB_HOST"
							from: #config.db.host
						}
					}
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

			// Sensitive fields — auto-discovered by #ModuleRelease and placed
			// in the opm-secrets component. Users provide concrete variants.
			password: schemas.#Secret & {
				$secretName: "db-credentials"
				$dataKey:    "password"
			}
			host: schemas.#Secret & {
				$secretName: "db-credentials"
				$dataKey:    "host"
			}
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
			// Debug values for secrets — use literals for local testing
			password: value: "dev-password"
			host: value:     "localhost"
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
			// Production: password is a literal, host references a pre-existing K8s Secret
			password: value: "super-secret-prod-password"
			host: {
				secretName: "cloud-sql-credentials"
				remoteKey:  "hostname"
			}
		}
	}
}

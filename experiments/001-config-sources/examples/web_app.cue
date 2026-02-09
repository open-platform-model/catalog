package examples

import (
	core "example.com/config-sources/core"
	workload_resources "example.com/config-sources/resources/workload"
	config_resources "example.com/config-sources/resources/config"
	workload_traits "example.com/config-sources/traits/workload"
	network_traits "example.com/config-sources/traits/network"
)

/////////////////////////////////////////////////////////////////
//// Web App Example — demonstrates ConfigSource usage
/////////////////////////////////////////////////////////////////

webAppComponent: core.#Component & {
	metadata: {
		name: "web-app"
		labels: {
			"core.opmodel.dev/workload-type": "stateless"
		}
	}

	// Compose resources and traits
	workload_resources.#Container
	config_resources.#ConfigSources
	workload_traits.#Scaling
	network_traits.#Expose

	spec: {
		scaling: count: 2

		// --- Config Sources ---
		configSources: {
			// Inline non-sensitive config
			"app-settings": {
				type: "config"
				data: {
					LOG_LEVEL: "info"
					APP_PORT:  "8080"
				}
			}

			// Inline sensitive data
			"db-credentials": {
				type: "secret"
				data: {
					username: "admin"
					password: "changeme"
				}
			}

			// External reference (resource already exists in cluster)
			"tls-cert": {
				type: "secret"
				externalRef: name: "wildcard-tls-cert"
			}
		}

		// --- Container ---
		container: {
			name:  "web"
			image: "myapp:v1.0.0"
			ports: http: {
				name:       "http"
				targetPort: 8080
			}

			env: {
				// Literal value (backward compatible)
				NODE_ENV: {
					name:  "NODE_ENV"
					value: "production"
				}
				// From inline config source
				LOG_LEVEL: {
					name: "LOG_LEVEL"
					from: {
						source: "app-settings"
						key:    "LOG_LEVEL"
					}
				}
				// From inline secret source
				DB_PASSWORD: {
					name: "DB_PASSWORD"
					from: {
						source: "db-credentials"
						key:    "password"
					}
				}
				DB_USER: {
					name: "DB_USER"
					from: {
						source: "db-credentials"
						key:    "username"
					}
				}
				// From external secret
				TLS_KEY: {
					name: "TLS_KEY"
					from: {
						source: "tls-cert"
						key:    "tls.key"
					}
				}
			}
		}

		// --- Expose ---
		expose: {
			ports: http: {
				name:       "http"
				targetPort: 8080
			}
			type: "ClusterIP"
		}
	}
}

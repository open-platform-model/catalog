package examples

import (
	core "example.com/config-sources/core"
)

/////////////////////////////////////////////////////////////////
//// Web App Module — parameterized deployment
/////////////////////////////////////////////////////////////////

webAppModule: core.#Module & {
	metadata: {
		apiVersion: "example.com/modules@v0"
		name:       "web-app-module"
		version:    "0.1.0"
	}

	#components: {
		"web-app": webAppComponent & {
			spec: {
				container: image: #config.image
				scaling: count:   #config.replicas
				configSources: {
					"app-settings": data: LOG_LEVEL: #config.logLevel
					"db-credentials": data: {
						username: #config.db.username
						password: #config.db.password
					}
				}
			}
		}
	}

	#config: {
		image:    string
		replicas: int & >=1
		logLevel: string
		db: {
			username: string
			password: string
		}
	}

	values: {
		image:    "myapp:v1.0.0"
		replicas: 2
		logLevel: "info"
		db: {
			username: "admin"
			password: "changeme"
		}
	}
}

/////////////////////////////////////////////////////////////////
//// Module Release — deploy-time overrides
/////////////////////////////////////////////////////////////////

webAppRelease: core.#ModuleRelease & {
	metadata: {
		name:      "web-app-prod"
		namespace: "production"
	}

	#module: webAppModule

	values: {
		image:    "myapp:v2.1.0"
		replicas: 3
		logLevel: "warn"
		db: {
			username: "prod-admin"
			password: "prod-secret-123"
		}
	}
}

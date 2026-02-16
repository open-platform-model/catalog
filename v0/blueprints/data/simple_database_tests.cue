@if(test)

package data

import (
	schemas "opmodel.dev/schemas@v0"
)

// =============================================================================
// SimpleDatabase Blueprint Tests
// =============================================================================

// Test: SimpleDatabaseBlueprint definition structure
_testSimpleDBBlueprintDef: #SimpleDatabaseBlueprint & {
	metadata: {
		apiVersion: "opmodel.dev/blueprints/data@v0"
		name:       "simple-database"
		fqn:        "opmodel.dev/blueprints/data@v0#SimpleDatabase"
	}
}

// Test: SimpleDatabase with Postgres
_testSimpleDBPostgres: #SimpleDatabase & {
	metadata: {
		name: "postgres-db"
		labels: "core.opmodel.dev/workload-type": "stateful"
	}
	spec: {
		simpleDatabase: {
			engine:   "postgres"
			version:  "16"
			dbName:   "mydb"
			username: "admin"
			password: "secret123"
			persistence: {
				enabled: true
				size:    "10Gi"
			}
		}
		// Verify auto-generated container fields
		container: {
			name:  "database"
			image: "postgres:16"
		}
	}
}

// Test: SimpleDatabase with MySQL
_testSimpleDBMySQL: #SimpleDatabase & {
	metadata: {
		name: "mysql-db"
		labels: "core.opmodel.dev/workload-type": "stateful"
	}
	spec: {
		simpleDatabase: {
			engine:   "mysql"
			version:  "8.0"
			dbName:   "appdb"
			username: "root"
			password: "mysql-pass"
			persistence: {
				enabled: true
				size:    "20Gi"
			}
		}
		container: {
			name:  "database"
			image: "mysql:8.0"
		}
	}
}

// Test: SimpleDatabase with MongoDB
_testSimpleDBMongo: #SimpleDatabase & {
	metadata: {
		name: "mongo-db"
		labels: "core.opmodel.dev/workload-type": "stateful"
	}
	spec: {
		simpleDatabase: {
			engine:   "mongodb"
			version:  "7"
			dbName:   "documents"
			username: "mongo-admin"
			password: "mongo-pass"
			persistence: {
				enabled: true
				size:    "50Gi"
			}
		}
		container: {
			name:  "database"
			image: "mongo:7"
		}
	}
}

// Test: SimpleDatabase with Redis
_testSimpleDBRedis: #SimpleDatabase & {
	metadata: {
		name: "redis-cache"
		labels: "core.opmodel.dev/workload-type": "stateful"
	}
	spec: {
		simpleDatabase: {
			engine:   "redis"
			version:  "7"
			dbName:   "cache"
			username: "default"
			password: "redis-pass"
			persistence: {
				enabled: true
				size:    "5Gi"
			}
		}
		container: {
			name:  "database"
			image: "redis:7"
		}
	}
}

// Test: Schema reference is correct
_testSimpleDBSchemaRef: {
	_s: schemas.#SimpleDatabaseSchema
}

// Test: SimpleDatabase environment variable verification
_testSimpleDBEnvVars: #SimpleDatabase & {
	metadata: {
		name: "env-test-db"
		labels: "core.opmodel.dev/workload-type": "stateful"
	}
	spec: {
		simpleDatabase: {
			engine:   "postgres"
			version:  "16"
			dbName:   "testdb"
			username: "testuser"
			password: "testpass"
		}
		// Verify environment variables are set correctly
		container: {
			name:  "database"
			image: "postgres:16"
			env: {
				POSTGRES_DB: {
					name:  "POSTGRES_DB"
					value: "testdb"
				}
				POSTGRES_USER: {
					name:  "POSTGRES_USER"
					value: "testuser"
				}
				POSTGRES_PASSWORD: {
					name:  "POSTGRES_PASSWORD"
					value: "testpass"
				}
			}
		}
	}
}

// Test: SimpleDatabase with persistence disabled
_testSimpleDBNoPersistence: #SimpleDatabase & {
	metadata: {
		name: "cache-db"
		labels: "core.opmodel.dev/workload-type": "stateful"
	}
	spec: {
		simpleDatabase: {
			engine:   "redis"
			version:  "7"
			dbName:   "session"
			username: "default"
			password: "pass"
			persistence: {
				enabled: false
			}
		}
		container: {
			name:  "database"
			image: "redis:7"
		}
	}
}

@if(test)

package schemas

import (
	tst "experiments.dev/test-framework/testkit"
)

#tests: tst.#Tests & {

	// =========================================================================
	// #SimpleDatabaseSchema
	// =========================================================================

	simpleDatabase: [

		// ── Positive ──
		{
			name:       "postgres with persistence"
			definition: "#SimpleDatabaseSchema"
			input: {
				engine:   "postgres"
				version:  "16"
				dbName:   "mydb"
				username: "admin"
				password: "secret123"
				persistence: {
					enabled:      true
					size:         "10Gi"
					storageClass: "standard"
				}
			}
			assert: valid: true
		},
		{
			name:       "mysql"
			definition: "#SimpleDatabaseSchema"
			input: {
				engine:   "mysql"
				version:  "8.0"
				dbName:   "appdb"
				username: "root"
				password: "mysql-pass"
			}
			assert: valid: true
		},
		{
			name:       "mongodb with persistence"
			definition: "#SimpleDatabaseSchema"
			input: {
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
			assert: valid: true
		},
		{
			name:       "redis"
			definition: "#SimpleDatabaseSchema"
			input: {
				engine:   "redis"
				version:  "7"
				dbName:   "cache"
				username: "default"
				password: "redis-pass"
			}
			assert: valid: true
		},
		{
			name:       "persistence disabled"
			definition: "#SimpleDatabaseSchema"
			input: {
				engine:   "redis"
				version:  "7"
				dbName:   "session-cache"
				username: "default"
				password: "pass"
				persistence: enabled: false
			}
			assert: valid: true
		},

		// ── Negative ──
		{
			name:       "bad engine"
			definition: "#SimpleDatabaseSchema"
			input: {
				engine:   "sqlite"
				version:  "3"
				dbName:   "mydb"
				username: "admin"
				password: "secret"
			}
			assert: valid: false
		},
		{
			name:       "missing engine"
			definition: "#SimpleDatabaseSchema"
			input: {
				version:  "16"
				dbName:   "mydb"
				username: "admin"
				password: "secret"
			}
			assert: valid: false
		},
		{
			name:       "bad persistence size"
			definition: "#SimpleDatabaseSchema"
			input: {
				engine:   "postgres"
				version:  "16"
				dbName:   "mydb"
				username: "admin"
				password: "secret"
				persistence: {
					enabled: true
					size:    "10GB"
				}
			}
			assert: valid: false
		},
	]
}

@if(test)

package schemas

// =============================================================================
// Data Schema Tests
// =============================================================================

// ── SimpleDatabaseSchema ─────────────────────────────────────────

_testSimpleDBPostgres: #SimpleDatabaseSchema & {
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

_testSimpleDBMySQL: #SimpleDatabaseSchema & {
	engine:   "mysql"
	version:  "8.0"
	dbName:   "appdb"
	username: "root"
	password: "mysql-pass"
}

_testSimpleDBMongoDB: #SimpleDatabaseSchema & {
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

_testSimpleDBRedis: #SimpleDatabaseSchema & {
	engine:   "redis"
	version:  "7"
	dbName:   "cache"
	username: "default"
	password: "redis-pass"
}

// Test: persistence disabled
_testSimpleDBNoPersistence: #SimpleDatabaseSchema & {
	engine:   "redis"
	version:  "7"
	dbName:   "session-cache"
	username: "default"
	password: "pass"
	persistence: enabled: false
}

// =============================================================================
// Negative Tests
// =============================================================================

// ── SimpleDatabaseSchema Negatives ───────────────────────────────

// Negative tests moved to testdata/*.yaml files

// Negative tests moved to testdata/*.yaml files

package platform_construct

// Fixtures — concrete inputs reused across test files. Hidden (underscore
// prefix) so they do not appear in `cue export` output. Plain values, no
// @if(test) tag, so any non-test evaluation can still reference them.

// ---- Resource definitions (catalog vocabulary) ----

_containerResource: #Resource & {
	apiVersion: "opmodel.dev/core/v1alpha2"
	metadata: {
		modulePath: "opmodel.dev/opm/v1alpha2/resources/workload"
		name:       "container"
		version:    "v1"
		fqn:        "opmodel.dev/opm/v1alpha2/resources/workload/container@v1"
	}
}

_volumeResource: #Resource & {
	apiVersion: "opmodel.dev/core/v1alpha2"
	metadata: {
		modulePath: "opmodel.dev/opm/v1alpha2/resources/storage"
		name:       "volume"
		version:    "v1"
		fqn:        "opmodel.dev/opm/v1alpha2/resources/storage/volume@v1"
	}
}

// ---- Trait definitions ----

_exposeTrait: #Trait & {
	apiVersion: "opmodel.dev/core/v1alpha2"
	metadata: {
		modulePath: "opmodel.dev/opm/v1alpha2/traits/network"
		name:       "expose"
		version:    "v1"
		fqn:        "opmodel.dev/opm/v1alpha2/traits/network/expose@v1"
	}
}

_backupTrait: #Trait & {
	apiVersion: "opmodel.dev/core/v1alpha2"
	metadata: {
		modulePath: "opmodel.dev/opm/v1alpha2/operations/backup"
		name:       "backup-trait"
		version:    "v1"
		fqn:        "opmodel.dev/opm/v1alpha2/operations/backup/backup-trait@v1"
	}
}

// ---- Claim definitions ----

_managedDatabaseClaim: #Claim & {
	apiVersion: "opmodel.dev/opm/v1alpha2"
	metadata: {
		modulePath: "opmodel.dev/opm/v1alpha2/claims/data"
		name:       "managed-database"
		version:    "v1"
		fqn:        "opmodel.dev/opm/v1alpha2/claims/data/managed-database@v1"
	}
}

_backupClaim: #Claim & {
	apiVersion: "opmodel.dev/opm/v1alpha2"
	metadata: {
		modulePath: "opmodel.dev/opm/v1alpha2/operations/backup"
		name:       "backup-claim"
		version:    "v1"
		fqn:        "opmodel.dev/opm/v1alpha2/operations/backup/backup-claim@v1"
	}
}

_unfulfilledClaim: #Claim & {
	apiVersion: "example.com/platform/v1alpha2"
	metadata: {
		modulePath: "example.com/platform/v1alpha2/claims"
		name:       "unfulfilled"
		version:    "v1"
		fqn:        "example.com/platform/v1alpha2/claims/unfulfilled@v1"
	}
}

// ---- Transformers ----

_deploymentTransformer: #ComponentTransformer & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha2/providers/kubernetes"
		name:        "deployment-transformer"
		version:     "v1"
		fqn:         "opmodel.dev/opm/v1alpha2/providers/kubernetes/deployment-transformer@v1"
		description: "Renders Container resource → Deployment"
	}
	requiredResources: (_containerResource.metadata.fqn): _
}

_pgManagedDatabaseTransformer: #ComponentTransformer & {
	metadata: {
		modulePath:  "vendor.com/postgres-operator"
		name:        "managed-database-transformer"
		version:     "v1"
		fqn:         "vendor.com/postgres-operator/managed-database-transformer@v1"
		description: "Postgres operator fulfils ManagedDatabaseClaim"
	}
	requiredClaims: (_managedDatabaseClaim.metadata.fqn): _
}

// Second fulfiller for ManagedDatabaseClaim — used in D13 multi-fulfiller test.
_aivenManagedDatabaseTransformer: #ComponentTransformer & {
	metadata: {
		modulePath:  "aiven.io/operator"
		name:        "aiven-managed-database-transformer"
		version:     "v1"
		fqn:         "aiven.io/operator/aiven-managed-database-transformer@v1"
		description: "Aiven operator fulfils ManagedDatabaseClaim"
	}
	requiredClaims: (_managedDatabaseClaim.metadata.fqn): _
}

_backupScheduleTransformer: #ModuleTransformer & {
	metadata: {
		modulePath:  "opmodel.dev/k8up/v1alpha2/transformers"
		name:        "backup-schedule-transformer"
		version:     "v1"
		fqn:         "opmodel.dev/k8up/v1alpha2/transformers/backup-schedule-transformer@v1"
		description: "Renders BackupClaim + BackupTrait → K8up Schedule + Backend"
	}
	requiredClaims: (_backupClaim.metadata.fqn): _
	requiresComponents: traits: (_backupTrait.metadata.fqn): _
}

// ---- Modules ----

_opmCoreModule: #Module & {
	metadata: {
		modulePath: "opmodel.dev/opm/v1alpha2"
		name:       "opm-kubernetes-core"
		version:    "0.1.0"
		fqn:        "opmodel.dev/opm/v1alpha2/opm-kubernetes-core:0.1.0"
		uuid:       "00000000-0000-0000-0000-000000000001"
	}
	#defines: {
		resources: {
			(_containerResource.metadata.fqn): _containerResource
			(_volumeResource.metadata.fqn):    _volumeResource
		}
		traits: {
			(_exposeTrait.metadata.fqn): _exposeTrait
		}
		claims: {
			(_managedDatabaseClaim.metadata.fqn): _managedDatabaseClaim
		}
		transformers: {
			(_deploymentTransformer.metadata.fqn): _deploymentTransformer
		}
	}
}

_postgresOperatorModule: #Module & {
	metadata: {
		modulePath: "vendor.com/postgres-operator"
		name:       "postgres"
		version:    "0.5.0"
		fqn:        "vendor.com/postgres-operator/postgres:0.5.0"
		uuid:       "00000000-0000-0000-0000-000000000002"
	}
	#defines: transformers: {
		(_pgManagedDatabaseTransformer.metadata.fqn): _pgManagedDatabaseTransformer
	}
}

_aivenOperatorModule: #Module & {
	metadata: {
		modulePath: "aiven.io/operator"
		name:       "aiven-postgres"
		version:    "0.1.0"
		fqn:        "aiven.io/operator/aiven-postgres:0.1.0"
		uuid:       "00000000-0000-0000-0000-000000000003"
	}
	#defines: transformers: {
		(_aivenManagedDatabaseTransformer.metadata.fqn): _aivenManagedDatabaseTransformer
	}
}

_k8upModule: #Module & {
	metadata: {
		modulePath: "opmodel.dev/k8up/v1alpha2"
		name:       "k8up"
		version:    "1.0.0"
		fqn:        "opmodel.dev/k8up/v1alpha2/k8up:1.0.0"
		uuid:       "00000000-0000-0000-0000-000000000004"
	}
	#defines: {
		traits: {
			(_backupTrait.metadata.fqn): _backupTrait
		}
		claims: {
			(_backupClaim.metadata.fqn): _backupClaim
		}
		transformers: {
			(_backupScheduleTransformer.metadata.fqn): _backupScheduleTransformer
		}
	}
}

// Consumer web-app — uses container resource and claims a database.
_consumerWebApp: #Module & {
	metadata: {
		modulePath: "example.com/apps"
		name:       "web-app"
		version:    "0.1.0"
		fqn:        "example.com/apps/web-app:0.1.0"
		uuid:       "00000000-0000-0000-0000-000000000010"
	}
	#components: {
		web: {
			metadata: name:                                "web"
			#resources: (_containerResource.metadata.fqn): _
			#claims: db:                                   _managedDatabaseClaim
		}
	}
}

// Consumer with an unfulfilled Claim — drives unmatched walker test.
_consumerUnfulfilled: #Module & {
	metadata: {
		modulePath: "example.com/apps"
		name:       "weird-app"
		version:    "0.1.0"
		fqn:        "example.com/apps/weird-app:0.1.0"
		uuid:       "00000000-0000-0000-0000-000000000011"
	}
	#components: {
		main: {
			metadata: name:                                "main"
			#resources: (_containerResource.metadata.fqn): _
			#claims: weird:                                _unfulfilledClaim
		}
	}
}

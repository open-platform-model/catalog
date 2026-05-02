package claims

// Fixtures — concrete inputs reused across test files. Hidden (underscore
// prefix) so they don't appear in `cue export` output. Plain values, no
// @if(test) tag, so any non-test evaluation can still reference them.
//
// Coverage:
//   - Resources, Traits — copied from 002 (Container, Volume, Expose, Backup).
//   - Quartet pattern (CL-D6) — #ManagedDatabaseSpec + #ManagedDatabaseStatus
//     + _managedDatabaseClaim. #HostnameSpec + #HostnameStatus +
//     _hostnameClaim. #BackupSpec + _backupClaim (side-effect-only, no
//     status pin).
//   - Component-scope fulfiller — _pgManagedDatabaseTransformer writes
//     {host, port, secretName}.
//   - Module-scope fulfillers — _k8upBackupScheduleTransformer (side-effect-
//     only, requiresComponents.traits gate); _dnsHostnameTransformer (writes
//     {fqdn}, no gate).
//   - Render transformers — _deploymentTransformer (reads injected status
//     for env vars), _serviceTransformer (002).
//   - Modules — opm-core, postgres-operator, k8up, dns publishers; consumers
//     web-app, strix-media (Example 7), strix-no-trait (gate-block test),
//     side-effect-only, with-chain, with-hostname, unfulfilled.
//   - Multi-fulfiller probes — _aivenManagedDatabaseTransformer (component-
//     scope alt) and _alternateK8upTransformer (module-scope alt).

// ============================================================
// Resources
// ============================================================

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

// ============================================================
// Traits
// ============================================================

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

// ============================================================
// Claim quartets (CL-D6)
// ============================================================

// ---- ManagedDatabase quartet ----

#ManagedDatabaseSpec: {
	engine!:  "postgres" | "mysql" | "mongodb"
	version!: string
	sizeGB:   int & >=1 | *10
}

#ManagedDatabaseStatus: {
	host!:       string
	port!:       int
	secretName!: string
}

_managedDatabaseClaim: #Claim & {
	apiVersion: "opmodel.dev/opm/v1alpha2"
	metadata: {
		modulePath: "opmodel.dev/opm/v1alpha2/claims/data"
		name:       "managed-database"
		version:    "v1"
	}
	#spec?:   #ManagedDatabaseSpec
	#status?: #ManagedDatabaseStatus
}

// ---- Backup quartet (side-effect-only — no status pin) ----

#BackupSpec: {
	schedule!: string
	backend!:  string
	retention?: {
		keepDaily?: int
	}
}

_backupClaim: #Claim & {
	apiVersion: "opmodel.dev/opm/v1alpha2"
	metadata: {
		modulePath: "opmodel.dev/opm/v1alpha2/operations/backup"
		name:       "backup-claim"
		version:    "v1"
	}
	#spec?: #BackupSpec
	// No #status pin — fulfiller side-effect-only.
}

// ---- Hostname quartet (module-scope, with status) ----

#HostnameSpec: {
	name!: string
}

#HostnameStatus: {
	fqdn!: string
}

_hostnameClaim: #Claim & {
	apiVersion: "opmodel.dev/opm/v1alpha2"
	metadata: {
		modulePath: "opmodel.dev/opm/v1alpha2/claims/network"
		name:       "hostname"
		version:    "v1"
	}
	#spec?:   #HostnameSpec
	#status?: #HostnameStatus
}

// ---- Unfulfilled (vendor-named, no fulfiller) ----

_unfulfilledClaim: #Claim & {
	apiVersion: "example.com/platform/v1alpha2"
	metadata: {
		modulePath: "example.com/platform/v1alpha2/claims"
		name:       "unfulfilled"
		version:    "v1"
	}
}

// ============================================================
// Component-scope transformers
// ============================================================

// _deploymentTransformer — reads #component.spec for replicas/image/port
// AND reads #component.#claims.db.#status.{host,port} (when present) to
// populate environment variables. Drives t09 + t12 (status consumption).
_deploymentTransformer: #ComponentTransformer & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha2/providers/kubernetes"
		name:        "deployment-transformer"
		version:     "v1"
		fqn:         "opmodel.dev/opm/v1alpha2/providers/kubernetes/deployment-transformer@v1"
		description: "Renders Container resource → apps/v1 Deployment"
	}
	requiredResources: (_containerResource.metadata.fqn): _

	producesKinds: ["apps/v1.Deployment"]

	#transform: {
		#moduleRelease: _
		#component:     _
		#context:       #TransformerContext

		if #context.release.name != _|_
		if #context.component.name != _|_
		if #component.spec != _|_ {
			// Build env list from injected db claim status when present.
			// Iterate-and-filter to avoid strict-mode subscript issues.
			let _dbStatuses = [
				if #component.#claims != _|_
				for cId, c in #component.#claims
				if cId == "db"
				if c.#status != _|_
				if c.#status.host != _|_ {c.#status},
			]

			output: {
				apiVersion: "apps/v1"
				kind:       "Deployment"
				metadata: {
					name:      "\(#context.release.name)-\(#context.component.name)"
					namespace: #context.release.namespace
					labels: {
						"app.kubernetes.io/name":     #context.component.name
						"app.kubernetes.io/instance": #context.release.name
					}
				}
				spec: {
					replicas: #component.spec.replicas
					selector: matchLabels: "app.kubernetes.io/name": #context.component.name
					template: {
						metadata: labels: "app.kubernetes.io/name": #context.component.name
						spec: containers: [{
							name:  #context.component.name
							image: #component.spec.image
							if #component.spec.port != _|_ {
								ports: [{containerPort: #component.spec.port}]
							}
							if len(_dbStatuses) > 0 {
								env: [
									{name: "DATABASE_HOST", value: _dbStatuses[0].host},
									{name: "DATABASE_PORT", value: "\(_dbStatuses[0].port)"},
								]
							}
						}]
					}
				}
			}
		}
	}
}

_serviceTransformer: #ComponentTransformer & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha2/providers/kubernetes"
		name:        "service-transformer"
		version:     "v1"
		fqn:         "opmodel.dev/opm/v1alpha2/providers/kubernetes/service-transformer@v1"
		description: "Renders Expose trait → v1 Service"
	}
	requiredTraits: (_exposeTrait.metadata.fqn): _

	producesKinds: ["v1.Service"]

	#transform: {
		#moduleRelease: _
		#component:     _
		#context:       #TransformerContext

		if #context.release.name != _|_
		if #context.component.name != _|_
		if #component.spec != _|_ {
			output: {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name:      "\(#context.release.name)-\(#context.component.name)"
					namespace: #context.release.namespace
				}
				spec: {
					selector: "app.kubernetes.io/name": #context.component.name
					ports: [{
						port:       #component.spec.port
						targetPort: #component.spec.port
					}]
				}
			}
		}
	}
}

// _pgManagedDatabaseTransformer — fulfils ManagedDatabaseClaim.
// Walks #component.#claims for FQN match, emits a Postgres CR AND
// #statusWrites: (claimId): { host, port, secretName }. Keystone of
// component-scope status writeback.
_pgManagedDatabaseTransformer: #ComponentTransformer & {
	metadata: {
		modulePath:  "vendor.com/postgres-operator"
		name:        "managed-database-transformer"
		version:     "v1"
		fqn:         "vendor.com/postgres-operator/managed-database-transformer@v1"
		description: "Postgres operator fulfils ManagedDatabaseClaim"
	}
	requiredClaims: (_managedDatabaseClaim.metadata.fqn): _

	producesKinds: ["postgres.vendor.com/v1.Postgres"]

	#transform: {
		#moduleRelease: _
		#component:     _
		#context:       #TransformerContext

		if #context.release.name != _|_
		if #context.component.name != _|_
		if #component.#claims != _|_ {
			let _matched = [
				for cId, c in #component.#claims
				if c.metadata.fqn == _managedDatabaseClaim.metadata.fqn {
					{id: cId, claim: c}
				},
			]
			if len(_matched) > 0 {
				let _e = _matched[0]
				let _crName = "\(#context.release.name)-\(#context.component.name)-\(_e.id)"

				#statusWrites: (_e.id): {
					host:       "\(_crName).\(#context.release.namespace).svc.cluster.local"
					port:       5432
					secretName: "\(_crName)-credentials"
				}

				output: {
					apiVersion: "postgres.vendor.com/v1"
					kind:       "Postgres"
					metadata: {
						name:      _crName
						namespace: #context.release.namespace
					}
					spec: {
						engine:  _e.claim.#spec.engine
						version: _e.claim.#spec.version
						if _e.claim.#spec.sizeGB != _|_ {
							sizeGB: _e.claim.#spec.sizeGB
						}
					}
				}
			}
		}
	}
}

// _aivenManagedDatabaseTransformer — alternate component-scope fulfiller.
// Used by n02 (multi-fulfiller diagnostic) — registering both alongside
// _pgManagedDatabaseTransformer creates two transformers for the same
// requiredClaim FQN, which #Platform._noMultiFulfiller rejects.
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

// ============================================================
// Module-scope transformers
// ============================================================

// _k8upBackupScheduleTransformer — module-scope. Fulfils BackupClaim,
// requiresComponents.traits gate (must have at least one component carrying
// #BackupTrait). Side-effect-only — NO #statusWrites.
_k8upBackupScheduleTransformer: #ModuleTransformer & {
	metadata: {
		modulePath:  "opmodel.dev/k8up/v1alpha2/transformers"
		name:        "backup-schedule-transformer"
		version:     "v1"
		fqn:         "opmodel.dev/k8up/v1alpha2/transformers/backup-schedule-transformer@v1"
		description: "Renders module-level BackupClaim + BackupTrait → K8up Schedule"
	}
	requiredClaims: (_backupClaim.metadata.fqn): _
	requiresComponents: traits: (_backupTrait.metadata.fqn): _

	producesKinds: ["k8up.io/v1.Schedule"]

	#transform: {
		#moduleRelease: _
		#context:       #TransformerContext

		if #context.release.name != _|_
		if #moduleRelease.#module != _|_ {
			let _bearers = [
				if #moduleRelease.#module.#components != _|_
				for cName, cmp in #moduleRelease.#module.#components
				let _hasTrait = [
					if cmp.#traits != _|_
					for fqn, _ in cmp.#traits
					if fqn == _backupTrait.metadata.fqn {true},
				]
				if len(_hasTrait) > 0 {cName},
			]
			let _matched = [
				if #moduleRelease.#module.#claims != _|_
				for cId, c in #moduleRelease.#module.#claims
				if c.metadata.fqn == _backupClaim.metadata.fqn {
					{id: cId, claim: c}
				},
			]
			if len(_matched) > 0 if len(_bearers) > 0 {
				let _e = _matched[0]
				output: {
					apiVersion: "k8up.io/v1"
					kind:       "Schedule"
					metadata: {
						name:      "\(#context.release.name)-\(_e.id)"
						namespace: #context.release.namespace
					}
					spec: {
						schedule: _e.claim.#spec.schedule
						backend:  _e.claim.#spec.backend
						targets: [for n in _bearers {n}]
					}
				}
			}
		}
	}
}

// _dnsHostnameTransformer — module-scope. Fulfils HostnameClaim, no gate.
// Writes #statusWrites.<id>.fqdn. Drives t08 (module-scope status writeback).
_dnsHostnameTransformer: #ModuleTransformer & {
	metadata: {
		modulePath:  "opmodel.dev/dns/v1alpha2/transformers"
		name:        "hostname-transformer"
		version:     "v1"
		fqn:         "opmodel.dev/dns/v1alpha2/transformers/hostname-transformer@v1"
		description: "Allocates a DNS record for module-level HostnameClaim"
	}
	requiredClaims: (_hostnameClaim.metadata.fqn): _

	producesKinds: ["dns.vendor.com/v1.Record"]

	#transform: {
		#moduleRelease: _
		#context:       #TransformerContext

		if #context.release.name != _|_
		if #moduleRelease.#module != _|_
		if #moduleRelease.#module.#claims != _|_ {
			let _matched = [
				for cId, c in #moduleRelease.#module.#claims
				if c.metadata.fqn == _hostnameClaim.metadata.fqn {
					{id: cId, claim: c}
				},
			]
			if len(_matched) > 0 {
				let _e = _matched[0]
				let _logical = _e.claim.#spec.name
				let _fqdn = "\(_logical).example.com"

				#statusWrites: (_e.id): {
					fqdn: _fqdn
				}

				output: {
					apiVersion: "dns.vendor.com/v1"
					kind:       "Record"
					metadata: {
						name:      "\(#context.release.name)-\(_e.id)"
						namespace: #context.release.namespace
					}
					spec: {
						host: _logical
						zone: "example.com"
					}
				}
			}
		}
	}
}

// _alternateK8upTransformer — module-scope alt fulfiller for BackupClaim.
// Used by n05 (module-scope multi-fulfiller diagnostic).
_alternateK8upTransformer: #ModuleTransformer & {
	metadata: {
		modulePath:  "alternate.io/backup"
		name:        "alt-backup-transformer"
		version:     "v1"
		fqn:         "alternate.io/backup/alt-backup-transformer@v1"
		description: "Alt module-scope BackupClaim fulfiller (multi-fulfiller probe)"
	}
	requiredClaims: (_backupClaim.metadata.fqn): _
}

// ============================================================
// Catalog-side modules (publishers)
// ============================================================

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
			(_serviceTransformer.metadata.fqn):    _serviceTransformer
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
			(_k8upBackupScheduleTransformer.metadata.fqn): _k8upBackupScheduleTransformer
		}
	}
}

_dnsModule: #Module & {
	metadata: {
		modulePath: "opmodel.dev/dns/v1alpha2"
		name:       "dns-provider"
		version:    "0.1.0"
		fqn:        "opmodel.dev/dns/v1alpha2/dns-provider:0.1.0"
		uuid:       "00000000-0000-0000-0000-000000000005"
	}
	#defines: {
		claims: {
			(_hostnameClaim.metadata.fqn): _hostnameClaim
		}
		transformers: {
			(_dnsHostnameTransformer.metadata.fqn): _dnsHostnameTransformer
		}
	}
}

_alternateK8upModule: #Module & {
	metadata: {
		modulePath: "alternate.io/backup"
		name:       "alt-backup"
		version:    "0.1.0"
		fqn:        "alternate.io/backup/alt-backup:0.1.0"
		uuid:       "00000000-0000-0000-0000-000000000006"
	}
	#defines: transformers: {
		(_alternateK8upTransformer.metadata.fqn): _alternateK8upTransformer
	}
}

// ============================================================
// Consumer modules
// ============================================================

// Component-scope claim only — drives t04, t07, t09 (status consumption),
// t12 (depth-1 chain).
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
			metadata: {
				name: "web"
				labels: "app.kubernetes.io/name": "web"
			}
			#resources: (_containerResource.metadata.fqn): _
			#traits: (_exposeTrait.metadata.fqn):          _
			#claims: db: _managedDatabaseClaim & {
				#spec: {
					engine:  "postgres"
					version: "16"
				}
			}
			spec: {
				image:    "nginx:1.27"
				replicas: 2
				port:     8080
			}
		}
	}
}

_webAppRelease: #ModuleRelease & {
	#module:   _consumerWebApp
	name:      "demo"
	namespace: "apps"
	uuid:      "00000000-0000-0000-0000-0000000000a0"
}

// Example 7 keystone — module-level BackupClaim + per-component BackupTrait.
// app + db both bear the trait, so the K8up gate passes. Drives t05, t10.
_consumerStrixMedia: #Module & {
	metadata: {
		modulePath: "example.com/apps"
		name:       "strix-media"
		version:    "0.1.0"
		fqn:        "example.com/apps/strix-media:0.1.0"
		uuid:       "00000000-0000-0000-0000-000000000011"
	}
	#components: {
		app: {
			metadata: name:                                "app"
			#resources: (_containerResource.metadata.fqn): _
			#traits: (_backupTrait.metadata.fqn):          _
			spec: {
				image:    "strix:0.1.0"
				replicas: 1
			}
		}
		db: {
			metadata: name:                                "db"
			#resources: (_containerResource.metadata.fqn): _
			#traits: (_backupTrait.metadata.fqn):          _
			spec: {
				image:    "postgres:16"
				replicas: 1
			}
		}
	}
	#claims: nightly: _backupClaim & {
		#spec: {
			schedule: "0 2 * * *"
			backend:  "offsite-b2"
		}
	}
}

_strixMediaRelease: #ModuleRelease & {
	#module:   _consumerStrixMedia
	name:      "strix-prod"
	namespace: "media"
	uuid:      "00000000-0000-0000-0000-0000000000a1"
}

// Same shape as _consumerStrixMedia but neither component carries the
// backup trait — drives t06 (gate blocks dispatch).
_consumerStrixNoTrait: #Module & {
	metadata: {
		modulePath: "example.com/apps"
		name:       "strix-no-trait"
		version:    "0.1.0"
		fqn:        "example.com/apps/strix-no-trait:0.1.0"
		uuid:       "00000000-0000-0000-0000-000000000012"
	}
	#components: {
		app: {
			metadata: name:                                "app"
			#resources: (_containerResource.metadata.fqn): _
			spec: {
				image:    "strix:0.1.0"
				replicas: 1
			}
		}
		db: {
			metadata: name:                                "db"
			#resources: (_containerResource.metadata.fqn): _
			spec: {
				image:    "postgres:16"
				replicas: 1
			}
		}
	}
	#claims: nightly: _backupClaim & {
		#spec: {
			schedule: "0 2 * * *"
			backend:  "offsite-b2"
		}
	}
}

_strixNoTraitRelease: #ModuleRelease & {
	#module:   _consumerStrixNoTrait
	name:      "strix-prod"
	namespace: "media"
	uuid:      "00000000-0000-0000-0000-0000000000a2"
}

// Consumer with a side-effect-only (no #statusWrites) fulfiller — verifies
// t11 (#status stays empty).
_consumerSideEffectOnly: #Module & {
	metadata: {
		modulePath: "example.com/apps"
		name:       "lone-app"
		version:    "0.1.0"
		fqn:        "example.com/apps/lone-app:0.1.0"
		uuid:       "00000000-0000-0000-0000-000000000013"
	}
	#components: {
		app: {
			metadata: name:                                "app"
			#resources: (_containerResource.metadata.fqn): _
			#traits: (_backupTrait.metadata.fqn):          _
			spec: {
				image:    "lone:0.1.0"
				replicas: 1
			}
		}
	}
	#claims: nightly: _backupClaim & {
		#spec: {
			schedule: "0 4 * * *"
			backend:  "local-disk"
		}
	}
}

_sideEffectRelease: #ModuleRelease & {
	#module:   _consumerSideEffectOnly
	name:      "lone"
	namespace: "apps"
	uuid:      "00000000-0000-0000-0000-0000000000a3"
}

// Module with module-level HostnameClaim — drives t08 (module-scope writeback)
// and t13 (full pipeline).
_consumerWithHostname: #Module & {
	metadata: {
		modulePath: "example.com/apps"
		name:       "ingress-app"
		version:    "0.1.0"
		fqn:        "example.com/apps/ingress-app:0.1.0"
		uuid:       "00000000-0000-0000-0000-000000000014"
	}
	#components: {
		web: {
			metadata: {
				name: "web"
				labels: "app.kubernetes.io/name": "web"
			}
			#resources: (_containerResource.metadata.fqn): _
			#traits: (_exposeTrait.metadata.fqn):          _
			#claims: db: _managedDatabaseClaim & {
				#spec: {
					engine:  "postgres"
					version: "18"
				}
			}
			spec: {
				image:    "nginx:1.27"
				replicas: 2
				port:     8080
			}
		}
	}
	#claims: edge: _hostnameClaim & {
		#spec: name: "ingress-app"
	}
}

_withHostnameRelease: #ModuleRelease & {
	#module:   _consumerWithHostname
	name:      "demo"
	namespace: "apps"
	uuid:      "00000000-0000-0000-0000-0000000000a4"
}

// Consumer with unfulfilled claim — drives n03.
_consumerUnfulfilled: #Module & {
	metadata: {
		modulePath: "example.com/apps"
		name:       "weird-app"
		version:    "0.1.0"
		fqn:        "example.com/apps/weird-app:0.1.0"
		uuid:       "00000000-0000-0000-0000-000000000015"
	}
	#components: {
		main: {
			metadata: name:                                "main"
			#resources: (_containerResource.metadata.fqn): _
			#claims: weird:                                _unfulfilledClaim
		}
	}
}

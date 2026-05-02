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
		description: "Renders Container resource → apps/v1 Deployment"
	}
	requiredResources: (_containerResource.metadata.fqn): _

	producesKinds: ["apps/v1.Deployment"]

	#transform: {
		#moduleRelease: _
		#component:     _
		#context:       #TransformerContext

		// Body materialises only when the dispatcher unifies in concrete
		// #context + #component. Without this guard, fixture-time
		// evaluation triggers `required field missing: name` because
		// #TransformerContext.release.name is required.
		if #context.release.name != _|_
		if #context.component.name != _|_
		if #component.spec != _|_ {
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
			(_backupScheduleTransformer.metadata.fqn): _backupScheduleTransformer
		}
	}
}

// Consumer web-app — uses container resource, exposes a port, and claims
// a database. Carries a concrete spec so the slim render pipeline has real
// values to interpolate into the rendered Deployment / Service.
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
			#claims: db:                                   _managedDatabaseClaim
			spec: {
				image:    "nginx:1.27"
				replicas: 2
				port:     8080
			}
		}
	}
}

// _webAppRelease — concrete release for the slim pipeline showcase.
// Used by t11/t12; doubles as the value behind
//   cue eval -e '_pipelineFixture.#outputs' -t test ./...
// which dumps the rendered K8s manifests for visual inspection.
_webAppRelease: #ModuleRelease & {
	#module:   _consumerWebApp
	name:      "demo"
	namespace: "apps"
	uuid:      "00000000-0000-0000-0000-0000000000a0"
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

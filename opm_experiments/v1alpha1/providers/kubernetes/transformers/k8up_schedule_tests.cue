@if(test)

package transformers

// =============================================================================
// K8upScheduleTransformer Tests
// =============================================================================
//
// Run: cue vet -t test ./providers/kubernetes/transformers/...
// Or:  task test:opm_experiments   (from catalog/)
//
// Note: the transformer is exercised with fully-populated k8upBackup specs.
// In production the pipeline enriches #component.spec.k8upBackup by unifying
// with #K8upBackupDirectiveSchema (which provides defaults); here we set
// every field explicitly so defaults don't need to fire. Secret fields use
// plain {name, key} passthrough to avoid unifying with schemas.#Secret.

// Test: Minimal directive produces a structurally valid K8up Schedule CR.
// Asserts: name convention, schedule, default-like check/prune schedules
//          set explicitly, retention, S3 backend passthrough, repo password.
_testK8upScheduleMinimal: (#K8upScheduleTransformer.#transform & {
	#component: {
		metadata: name: "jellyfin"
		spec: k8upBackup: {
			schedule:      "0 2 * * *"
			checkSchedule: "0 4 * * 0"
			pruneSchedule: "0 5 * * 0"
			retention: {
				keepDaily:   7
				keepWeekly:  4
				keepMonthly: 6
			}
			repository: {
				format: "restic"
				s3: {
					endpoint: "http://garage.garage.svc:3900"
					bucket:   "jellyfin-backups"
					accessKeyID: {name: "jellyfin-backup-s3", key: "access-key-id"}
					secretAccessKey: {name: "jellyfin-backup-s3", key: "secret-access-key"}
				}
				password: {name: "jellyfin-backup-restic", key: "password"}
			}
			restore: jellyfin: {
				requiresScaleDown: true
				healthCheck: {
					path: "/health"
					port: 8096
				}
			}
		}
	}
	#context: (#TestCtx & {
		release:   "jellyfin"
		namespace: "media"
		component: "jellyfin"
	}).out
}).output & {
	apiVersion: "k8up.io/v1"
	kind:       "Schedule"
	metadata: {
		name:      "jellyfin-jellyfin-backup"
		namespace: "media"
	}
	spec: {
		backup: schedule: "0 2 * * *"
		check: schedule:  "0 4 * * 0"
		prune: schedule:  "0 5 * * 0"
		prune: retention: {
			keepDaily:   7
			keepWeekly:  4
			keepMonthly: 6
		}
		backend: s3: {
			endpoint: "http://garage.garage.svc:3900"
			bucket:   "jellyfin-backups"
			accessKeyIDSecretRef: {
				name: "jellyfin-backup-s3"
				key:  "access-key-id"
			}
			secretAccessKeySecretRef: {
				name: "jellyfin-backup-s3"
				key:  "secret-access-key"
			}
		}
		backend: repoPasswordSecretRef: {
			name: "jellyfin-backup-restic"
			key:  "password"
		}
	}
}

// Test: Custom check/prune schedules and retention override the baseline.
// Asserts: output reflects the overridden values; name convention uses the
//          release + component prefix.
_testK8upScheduleCustomRetention: (#K8upScheduleTransformer.#transform & {
	#component: {
		metadata: name: "postgres"
		spec: k8upBackup: {
			schedule:      "0 3 * * *"
			checkSchedule: "0 6 * * 1"
			pruneSchedule: "30 6 * * 1"
			retention: {
				keepDaily:   14
				keepWeekly:  8
				keepMonthly: 12
			}
			repository: {
				format: "restic"
				s3: {
					endpoint: "http://garage.garage.svc:3900"
					bucket:   "pg-backups"
					accessKeyID: {name: "pg-s3", key: "access-key-id"}
					secretAccessKey: {name: "pg-s3", key: "secret-access-key"}
				}
				password: {name: "pg-restic", key: "password"}
			}
		}
	}
	#context: (#TestCtx & {
		release:   "app"
		namespace: "app"
		component: "postgres"
	}).out
}).output & {
	spec: {
		backup: schedule: "0 3 * * *"
		check: schedule:  "0 6 * * 1"
		prune: schedule:  "30 6 * * 1"
		prune: retention: {
			keepDaily:   14
			keepWeekly:  8
			keepMonthly: 12
		}
	}
	metadata: name: "app-postgres-backup"
}

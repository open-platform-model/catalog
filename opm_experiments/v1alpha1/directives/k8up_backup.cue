// Package directives holds experimental #Directive definitions.
//
// Definitions here are not stable and may change shape, be renamed,
// or be removed without notice. See README.md for graduation criteria.
package directives

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	schemas "opmodel.dev/opm/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// K8upBackupDirective — unified backup + restore directive
/////////////////////////////////////////////////////////////////

// #K8upBackupDirective: single directive with three sub-blocks. The K8up
// Schedule transformer consumes scheduling + repository; the OPM CLI consumes
// repository + restore. See catalog/enhancements/009-backup-directive/.
#K8upBackupDirective: prim.#Directive & {
	metadata: {
		modulePath:  "opmodel.dev/opm-experiments/v1alpha1/directives"
		version:     "v1"
		name:        "k8up-backup"
		description: "K8up backup schedule, shared repository, and CLI restore procedure (experimental)"
		labels: {
			"directive.opmodel.dev/category": "data"
			"directive.opmodel.dev/provider": "k8up"
		}
	}

	#spec: close({k8upBackup: #K8upBackupDirectiveSchema})
}

// #K8upBackupDirectiveSchema:
//   - schedule / checkSchedule / pruneSchedule / retention — consumed by the
//     K8up Schedule transformer.
//   - repository — shared; consumed by both the transformer (backend) and the
//     CLI (restore).
//   - restore — CLI-only; keys MUST be component names that appear in the
//     parent Policy's appliesTo.components list. Definition order is restore
//     order.
#K8upBackupDirectiveSchema: {
	// ── Scheduling (transformer) ──────────────────────────────────────────

	// Backup cron schedule (required, no default). Module/release author must choose.
	schedule!: string

	// Restic repository integrity check cadence. Weekly by default.
	checkSchedule: *"0 4 * * 0" | string

	// Restic snapshot pruning cadence. Weekly by default.
	pruneSchedule: *"0 5 * * 0" | string

	// Restic retention policy. Mapped directly to `restic forget --prune` flags.
	retention: {
		keepDaily:   *7 | int
		keepWeekly:  *4 | int
		keepMonthly: *6 | int
	}

	// ── Repository (shared: transformer + CLI) ────────────────────────────

	// Backup repository connection. The transformer reads this to build the
	// K8up Schedule's backend. The CLI reads this to connect to the repo.
	repository!: {
		// Backup tool format. Determines which tool the CLI uses to browse
		// snapshots and run restores. K8up writes Restic repos.
		format: *"restic" | "kopia"

		// S3 storage backend (MinIO, Garage, AWS S3, etc.).
		s3!: {
			endpoint!:        string
			bucket!:          string
			accessKeyID!:     schemas.#Secret
			secretAccessKey!: schemas.#Secret
		}

		// Restic/Kopia repository encryption key.
		password!: schemas.#Secret
	}

	// ── Restore procedure (CLI only) ──────────────────────────────────────

	// Per-component restore metadata. Keys are component names. The CLI
	// restores in the order these keys are declared.
	restore?: [componentName=string]: {
		// Whether the CLI must scale the component's workload(s) to 0 before
		// restoring volumes. Most stateful workloads need this to avoid
		// corruption.
		requiresScaleDown: *true | bool

		// Optional HTTP health check polled after restore + scale-up.
		healthCheck?: {
			path!: string
			port!: int
		}
	}
}

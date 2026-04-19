// Package transformers holds experimental Kubernetes transformers that
// consume experimental directives/traits.
//
// Definitions here are not stable and may change shape, be renamed,
// or be removed without notice. See README.md for graduation criteria.
package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	exp_directives "opmodel.dev/opm_experiments/v1alpha1/directives@v1"
)

/////////////////////////////////////////////////////////////////
//// #ResolveSecretRef — shared with k8up catalog's helper
/////////////////////////////////////////////////////////////////

// #ResolveSecretRef resolves a schemas.#Secret (or plain {name, key} passthrough)
// into a K8up-compatible {name, key} secret reference. Duplicated from the
// k8up catalog (kept local to opm_experiments to avoid a new cross-module
// dependency during iteration).
#ResolveSecretRef: {
	X="in":  _
	#prefix: string

	out: {
		// Plain {name, key} passthrough — no $opm discriminator
		if X.$opm == _|_ {
			name: X.name
			key:  X.key
		}

		// #SecretK8sRef — pre-existing K8s Secret
		if X.$opm != _|_ if X.secretName != _|_ {
			name: X.secretName
			key:  X.remoteKey
		}

		// #SecretLiteral — OPM auto-creates the K8s Secret
		if X.$opm != _|_ if X.secretName == _|_ {
			name: "\(#prefix)-\(X.$secretName)"
			key:  X.$dataKey
		}
	}
}

/////////////////////////////////////////////////////////////////
//// K8upScheduleTransformer — consumes #K8upBackupDirective
/////////////////////////////////////////////////////////////////

// #K8upScheduleTransformer builds a K8up Schedule CR from a matched
// #K8upBackupDirective. One Schedule CR per component covered by the
// policy carrying the directive.
//
// PVC targeting is handled at the K8up layer, not here — see
// catalog/enhancements/009-backup-directive/07-open-questions.md Q1.
#K8upScheduleTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/opm-experiments/v1alpha1/providers/kubernetes/transformers"
		version:     "v0"
		name:        "k8up-schedule-transformer"
		description: "Generates a K8up Schedule CR from #K8upBackupDirective (experimental)"
		labels: {
			"core.opmodel.dev/resource-category": "backup"
			"core.opmodel.dev/resource-type":     "schedule"
			"transformer.opmodel.dev/stability":  "experimental"
		}
	}

	requiredLabels: {}
	requiredResources: {}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}
	requiredDirectives: {
		(exp_directives.#K8upBackupDirective.metadata.fqn): exp_directives.#K8upBackupDirective
	}
	optionalDirectives: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_d:           #component.spec.k8upBackup
		_name:        "\(#context.#moduleReleaseMetadata.name)-\(#context.#componentMetadata.name)-backup"
		_releaseName: #context.#moduleReleaseMetadata.name

		output: {
			apiVersion: "k8up.io/v1"
			kind:       "Schedule"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
			}
			spec: {
				backend: {
					repoPasswordSecretRef: (#ResolveSecretRef & {
						"in":    _d.repository.password
						#prefix: _releaseName
					}).out
					s3: {
						endpoint: _d.repository.s3.endpoint
						bucket:   _d.repository.s3.bucket
						accessKeyIDSecretRef: (#ResolveSecretRef & {
							"in":    _d.repository.s3.accessKeyID
							#prefix: _releaseName
						}).out
						secretAccessKeySecretRef: (#ResolveSecretRef & {
							"in":    _d.repository.s3.secretAccessKey
							#prefix: _releaseName
						}).out
					}
				}
				backup: schedule: _d.schedule
				check: schedule:  _d.checkSchedule
				prune: {
					schedule: _d.pruneSchedule
					retention: {
						keepDaily:   _d.retention.keepDaily
						keepWeekly:  _d.retention.keepWeekly
						keepMonthly: _d.retention.keepMonthly
					}
				}
			}
		}
	}
}

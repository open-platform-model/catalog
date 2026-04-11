package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/k8up/v1alpha1/resources/backup@v1"
)

// #ResolveSecretRef resolves a schemas.#Secret (or plain {name, key} passthrough)
// into a K8up-compatible {name: string, key: string} secret reference.
//
// Dispatch:
//   $opm present + secretName set (#SecretK8sRef) → {name: secretName, key: remoteKey}
//   $opm present + no secretName (#SecretLiteral) → {name: "{prefix}-{$secretName}", key: $dataKey}
//   $opm absent  (plain {name, key})              → passthrough (backward compatible)
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

// #ScheduleTransformer passes K8up Schedule resources through
// with OPM context applied (name prefix, namespace, labels).
// Resolves schemas.#Secret backend references to K8up {name, key} format.
#ScheduleTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/k8up/providers/kubernetes/transformers"
		version:     "v1"
		name:        "schedule-transformer"
		description: "Passes K8up Schedule resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "backup"
			"core.opmodel.dev/resource-type":     "schedule"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#ScheduleResource.metadata.fqn): res.#ScheduleResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_schedule:    #component.spec.schedule
		_name:        "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"
		_releaseName: #context.#moduleReleaseMetadata.name

		output: {
			apiVersion: "k8up.io/v1"
			kind:       "Schedule"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _schedule.metadata != _|_ {
					if _schedule.metadata.annotations != _|_ {
						annotations: _schedule.metadata.annotations
					}
				}
			}
			if _schedule.spec != _|_ {
				spec: {
					// Resolve backend secret references if present
					if _schedule.spec.backend != _|_ {
						backend: {
							if _schedule.spec.backend.repoPasswordSecretRef != _|_ {
								repoPasswordSecretRef: (#ResolveSecretRef & {
									"in":    _schedule.spec.backend.repoPasswordSecretRef
									#prefix: _releaseName
								}).out
							}
							if _schedule.spec.backend.s3 != _|_ {
								s3: {
									if _schedule.spec.backend.s3.endpoint != _|_ {
										endpoint: _schedule.spec.backend.s3.endpoint
									}
									if _schedule.spec.backend.s3.bucket != _|_ {
										bucket: _schedule.spec.backend.s3.bucket
									}
									if _schedule.spec.backend.s3.accessKeyIDSecretRef != _|_ {
										accessKeyIDSecretRef: (#ResolveSecretRef & {
											"in":    _schedule.spec.backend.s3.accessKeyIDSecretRef
											#prefix: _releaseName
										}).out
									}
									if _schedule.spec.backend.s3.secretAccessKeySecretRef != _|_ {
										secretAccessKeySecretRef: (#ResolveSecretRef & {
											"in":    _schedule.spec.backend.s3.secretAccessKeySecretRef
											#prefix: _releaseName
										}).out
									}
								}
							}
						}
					}

					// Pass through all non-backend fields unchanged
					if _schedule.spec.backup != _|_ {
						backup: _schedule.spec.backup
					}
					if _schedule.spec.check != _|_ {
						check: _schedule.spec.check
					}
					if _schedule.spec.prune != _|_ {
						prune: _schedule.spec.prune
					}
					if _schedule.spec.archive != _|_ {
						archive: _schedule.spec.archive
					}
				}
			}
		}
	}
}

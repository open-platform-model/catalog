package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/k8up/v1alpha1/resources/backup@v1"
)

// #PreBackupPodTransformer passes K8up PreBackupPod resources through
// with OPM context applied (name prefix, namespace, labels).
#PreBackupPodTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/k8up/providers/kubernetes/transformers"
		version:     "v1"
		name:        "pre-backup-pod-transformer"
		description: "Passes K8up PreBackupPod resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "backup"
			"core.opmodel.dev/resource-type":     "pre-backup-pod"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#PreBackupPodResource.metadata.fqn): res.#PreBackupPodResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_preBackupPod: #component.spec.preBackupPod
		_name:         "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "k8up.io/v1"
			kind:       "PreBackupPod"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _preBackupPod.metadata != _|_ {
					if _preBackupPod.metadata.annotations != _|_ {
						annotations: _preBackupPod.metadata.annotations
					}
				}
			}
			if _preBackupPod.spec != _|_ {
				spec: _preBackupPod.spec
			}
		}
	}
}

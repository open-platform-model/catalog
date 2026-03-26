package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/k8up/v1alpha1/resources/backup@v1"
)

// #RestoreTransformer passes K8up Restore resources through
// with OPM context applied (name prefix, namespace, labels).
#RestoreTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/k8up/providers/kubernetes/transformers"
		version:     "v1"
		name:        "restore-transformer"
		description: "Passes K8up Restore resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "backup"
			"core.opmodel.dev/resource-type":     "restore"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#RestoreResource.metadata.fqn): res.#RestoreResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_restore: #component.spec.restore
		_name:    "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "k8up.io/v1"
			kind:       "Restore"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _restore.metadata != _|_ {
					if _restore.metadata.annotations != _|_ {
						annotations: _restore.metadata.annotations
					}
				}
			}
			if _restore.spec != _|_ {
				spec: _restore.spec
			}
		}
	}
}

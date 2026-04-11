package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/k8up/v1alpha1/resources/backup@v1"
)

// #BackupTransformer passes K8up Backup resources through
// with OPM context applied (name prefix, namespace, labels).
#BackupTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/k8up/providers/kubernetes/transformers"
		version:     "v1"
		name:        "backup-transformer"
		description: "Passes K8up Backup resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "backup"
			"core.opmodel.dev/resource-type":     "backup"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#BackupResource.metadata.fqn): res.#BackupResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_backup: #component.spec.backup
		_name:   "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "k8up.io/v1"
			kind:       "Backup"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _backup.metadata != _|_ {
					if _backup.metadata.annotations != _|_ {
						annotations: _backup.metadata.annotations
					}
				}
			}
			if _backup.spec != _|_ {
				spec: _backup.spec
			}
		}
	}
}

package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1alpha1/resources/config@v1"
)

// #ConfigMapTransformer passes native Kubernetes ConfigMap resources through
// with OPM context applied (name prefix, namespace, labels).
#ConfigMapTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "configmap-transformer"
		description: "Passes native Kubernetes ConfigMap resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "config"
			"core.opmodel.dev/resource-type":     "configmap"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#ConfigMapResource.metadata.fqn): res.#ConfigMapResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_cm:   #component.spec.configmap
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _cm.metadata != _|_ {
					if _cm.metadata.annotations != _|_ {
						annotations: _cm.metadata.annotations
					}
				}
			}
			if _cm.data != _|_ {
				data: _cm.data
			}
			if _cm.binaryData != _|_ {
				binaryData: _cm.binaryData
			}
			if _cm.immutable != _|_ {
				immutable: _cm.immutable
			}
		}
	}
}

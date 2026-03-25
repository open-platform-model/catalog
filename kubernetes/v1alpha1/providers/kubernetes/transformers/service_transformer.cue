package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1alpha1/resources/network@v1"
)

// #ServiceTransformer passes native Kubernetes Service resources through
// with OPM context applied (name prefix, namespace, labels).
#ServiceTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "service-transformer"
		description: "Passes native Kubernetes Service resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "service"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#ServiceResource.metadata.fqn): res.#ServiceResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_svc:  #component.spec.service
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _svc.metadata != _|_ {
					if _svc.metadata.annotations != _|_ {
						annotations: _svc.metadata.annotations
					}
				}
			}
			if _svc.spec != _|_ {
				spec: _svc.spec
			}
		}
	}
}

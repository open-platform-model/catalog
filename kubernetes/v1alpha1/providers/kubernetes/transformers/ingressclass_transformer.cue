package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1alpha1/resources/network@v1"
)

// #IngressClassTransformer passes native Kubernetes IngressClass resources through
// with OPM context applied (name prefix, labels). IngressClass is cluster-scoped: no namespace.
#IngressClassTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "ingressclass-transformer"
		description: "Passes native Kubernetes IngressClass resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "ingressclass"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#IngressClassResource.metadata.fqn): res.#IngressClassResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_ic:   #component.spec.ingressclass
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "networking.k8s.io/v1"
			kind:       "IngressClass"
			metadata: {
				name:   _name
				labels: #context.labels
				if _ic.metadata != _|_ {
					if _ic.metadata.annotations != _|_ {
						annotations: _ic.metadata.annotations
					}
				}
			}
			if _ic.spec != _|_ {
				spec: _ic.spec
			}
		}
	}
}

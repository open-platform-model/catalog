package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1/resources/network@v1"
)

// #IngressTransformer passes native Kubernetes Ingress resources through
// with OPM context applied (name prefix, namespace, labels).
#IngressTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "ingress-transformer"
		description: "Passes native Kubernetes Ingress resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "ingress"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#IngressResource.metadata.fqn): res.#IngressResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_ing:  #component.spec.ingress
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "networking.k8s.io/v1"
			kind:       "Ingress"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _ing.metadata != _|_ {
					if _ing.metadata.annotations != _|_ {
						annotations: _ing.metadata.annotations
					}
				}
			}
			if _ing.spec != _|_ {
				spec: _ing.spec
			}
		}
	}
}

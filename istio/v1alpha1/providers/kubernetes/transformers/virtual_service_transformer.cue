package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/istio/v1alpha1/resources/network@v1"
)

// #VirtualServiceTransformer passes native Istio VirtualService resources through
// with OPM context applied (name prefix, namespace, labels).
#VirtualServiceTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/istio/providers/kubernetes/transformers"
		version:     "v1"
		name:        "virtual-service-transformer"
		description: "Passes native Istio VirtualService resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "virtual-service"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#VirtualServiceResource.metadata.fqn): res.#VirtualServiceResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_vs:   #component.spec.virtualService
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "networking.istio.io/v1"
			kind:       "VirtualService"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _vs.metadata != _|_ {
					if _vs.metadata.annotations != _|_ {
						annotations: _vs.metadata.annotations
					}
				}
			}
			if _vs.spec != _|_ {
				spec: _vs.spec
			}
		}
	}
}

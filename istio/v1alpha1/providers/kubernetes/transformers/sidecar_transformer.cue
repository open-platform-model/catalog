package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/istio/v1alpha1/resources/network@v1"
)

#SidecarTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/istio/providers/kubernetes/transformers"
		version:     "v1"
		name:        "sidecar-transformer"
		description: "Passes native Istio Sidecar resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "sidecar"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#SidecarResource.metadata.fqn): res.#SidecarResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_sc:   #component.spec.sidecar
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "networking.istio.io/v1"
			kind:       "Sidecar"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _sc.metadata != _|_ {
					if _sc.metadata.annotations != _|_ {
						annotations: _sc.metadata.annotations
					}
				}
			}
			if _sc.spec != _|_ {
				spec: _sc.spec
			}
		}
	}
}

package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/istio/v1alpha1/resources/network@v1"
)

#ProxyConfigTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/istio/providers/kubernetes/transformers"
		version:     "v1"
		name:        "proxy-config-transformer"
		description: "Passes native Istio ProxyConfig resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "proxy-config"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#ProxyConfigResource.metadata.fqn): res.#ProxyConfigResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_pc:   #component.spec.proxyConfig
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "networking.istio.io/v1beta1"
			kind:       "ProxyConfig"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _pc.metadata != _|_ {
					if _pc.metadata.annotations != _|_ {
						annotations: _pc.metadata.annotations
					}
				}
			}
			if _pc.spec != _|_ {
				spec: _pc.spec
			}
		}
	}
}

package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/gateway_api/v1alpha1/resources/network@v1"
)

// #TlsRouteTransformer passes native Gateway API TLSRoute resources through
// with OPM context applied (name prefix, namespace, labels).
#TlsRouteTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/providers/kubernetes/transformers"
		version:     "v1"
		name:        "tls-route-transformer"
		description: "Passes native Gateway API TLSRoute resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "tls-route"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#TlsRouteResource.metadata.fqn): res.#TlsRouteResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_tlsRoute: #component.spec.tlsRoute
		_name:     "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "gateway.networking.k8s.io/v1alpha2"
			kind:       "TLSRoute"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _tlsRoute.metadata != _|_ {
					if _tlsRoute.metadata.annotations != _|_ {
						annotations: _tlsRoute.metadata.annotations
					}
				}
			}
			if _tlsRoute.spec != _|_ {
				spec: _tlsRoute.spec
			}
		}
	}
}

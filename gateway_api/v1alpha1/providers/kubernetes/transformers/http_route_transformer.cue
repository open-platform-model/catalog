package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/gateway_api/v1alpha1/resources/network@v1"
)

// #HttpRouteTransformer passes native Gateway API HTTPRoute resources through
// with OPM context applied (name prefix, namespace, labels).
#HttpRouteTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/providers/kubernetes/transformers"
		version:     "v1"
		name:        "http-route-transformer"
		description: "Passes native Gateway API HTTPRoute resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "http-route"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#HttpRouteResource.metadata.fqn): res.#HttpRouteResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_httpRoute: #component.spec.httpRoute
		_name:      "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "gateway.networking.k8s.io/v1"
			kind:       "HTTPRoute"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _httpRoute.metadata != _|_ {
					if _httpRoute.metadata.annotations != _|_ {
						annotations: _httpRoute.metadata.annotations
					}
				}
			}
			if _httpRoute.spec != _|_ {
				spec: _httpRoute.spec
			}
		}
	}
}

package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/gateway_api/v1alpha1/resources/network@v1"
)

// #BackendTrafficPolicyTransformer passes native Gateway API BackendTrafficPolicy resources through
// with OPM context applied (name prefix, namespace, labels).
#BackendTrafficPolicyTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/providers/kubernetes/transformers"
		version:     "v1"
		name:        "backend-traffic-policy-transformer"
		description: "Passes native Gateway API BackendTrafficPolicy resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "backend-traffic-policy"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#BackendTrafficPolicyResource.metadata.fqn): res.#BackendTrafficPolicyResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_policy: #component.spec.backendTrafficPolicy
		_name:   "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "gateway.networking.x-k8s.io/v1alpha1"
			kind:       "XBackendTrafficPolicy"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _policy.metadata != _|_ {
					if _policy.metadata.annotations != _|_ {
						annotations: _policy.metadata.annotations
					}
				}
			}
			if _policy.spec != _|_ {
				spec: _policy.spec
			}
		}
	}
}

package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	xbtpV1alpha1 "opmodel.dev/gateway_api/v1alpha1/schemas/gateway/gateway.networking.x-k8s.io/xbackendtrafficpolicy/v1alpha1@v1"
)

// BackendTrafficPolicyTransformer creates Gateway API BackendTrafficPolicies from
// BackendTrafficPolicyResource components. This is an experimental Gateway API resource
// for configuring per-backend traffic behaviour such as session persistence and retries.
#BackendTrafficPolicyTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/providers/kubernetes/transformers"
		version:     "v1"
		name:        "backend-traffic-policy-transformer"
		description: "Creates experimental Gateway API BackendTrafficPolicies for backend traffic configuration"

		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "backend-traffic-policy"
		}
	}

	requiredLabels: {}

	requiredResources: {
		"opmodel.dev/gateway-api/resources/network/backend-traffic-policy@v1": _
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_policy: #component.spec.backendTrafficPolicy
		_name:   "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: xbtpV1alpha1.#XBackendTrafficPolicy & {
			apiVersion: "gateway.networking.x-k8s.io/v1alpha1"
			kind:       "XBackendTrafficPolicy"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if len(#context.componentAnnotations) > 0 {
					annotations: #context.componentAnnotations
				}
			}
			spec: {
				targetRefs: [_policy.targetRef]
				if _policy.sessionPersistence != _|_ {
					sessionPersistence: _policy.sessionPersistence
				}
				if _policy.retry != _|_ {
					retryConstraint: _policy.retry
				}
			}
		}
	}
}

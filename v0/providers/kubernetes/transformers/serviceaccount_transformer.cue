package transformers

import (
	core "opmodel.dev/core@v0"
	security_traits "opmodel.dev/traits/security@v0"
	k8scorev1 "opmodel.dev/schemas/kubernetes/core/v1@v0"
)

// ServiceAccountTransformer converts WorkloadIdentity traits to Kubernetes ServiceAccounts
#ServiceAccountTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "opmodel.dev/providers/kubernetes/transformers@v0"
		name:        "serviceaccount-transformer"
		description: "Converts WorkloadIdentity traits to Kubernetes ServiceAccounts"

		labels: {
			"core.opmodel.dev/resource-category": "security"
			"core.opmodel.dev/resource-type":     "serviceaccount"
		}
	}

	requiredLabels: {}
	requiredResources: {}
	optionalResources: {}

	// Required traits - WorkloadIdentity MUST be present
	requiredTraits: {
		"opmodel.dev/traits/security@v0#WorkloadIdentity": security_traits.#WorkloadIdentityTrait
	}

	optionalTraits: {}

	#transform: {
		#component: _
		#context:   core.#TransformerContext

		_workloadIdentity: #component.spec.workloadIdentity

		output: k8scorev1.#ServiceAccount & {
			apiVersion: "v1"
			kind:       "ServiceAccount"
			metadata: {
				name:      _workloadIdentity.name
				namespace: #context.namespace
				labels:    #context.labels
				// Include component annotations if present
				if len(#context.componentAnnotations) > 0 {
					annotations: #context.componentAnnotations
				}
			}
			automountServiceAccountToken: _workloadIdentity.automountToken
		}
	}
}

_testServiceAccountTransformer: #ServiceAccountTransformer.#transform & {
	#component: _testServiceAccountComponent
	#context:   _testContext
}

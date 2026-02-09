package transformers

import (
	core "example.com/config-sources/core"
	security_traits "example.com/config-sources/traits/security"
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

		output: {
			apiVersion: "v1"
			kind:       "ServiceAccount"
			metadata: {
				name:      _workloadIdentity.name
				namespace: #context.namespace
				labels:    #context.labels
			}
			automountServiceAccountToken: _workloadIdentity.automountToken
		}
	}
}

_testServiceAccountTransformer: #ServiceAccountTransformer.#transform & {
	#component: _testServiceAccountComponent
	#context:   _testContext
}

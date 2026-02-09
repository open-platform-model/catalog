package transformers

import (
	core "opmodel.dev/core@v0"
	security_resources "opmodel.dev/resources/security@v0"
)

// ServiceAccountTransformer converts WorkloadIdentity resources to Kubernetes ServiceAccounts
#ServiceAccountTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "opmodel.dev/providers/kubernetes/transformers@v0"
		name:        "serviceaccount-transformer"
		description: "Converts WorkloadIdentity resources to Kubernetes ServiceAccounts"

		labels: {
			"core.opmodel.dev/resource-category": "security"
			"core.opmodel.dev/resource-type":     "serviceaccount"
		}
	}

	requiredLabels: {}

	// Required resources - WorkloadIdentity MUST be present
	requiredResources: {
		"opmodel.dev/resources/security@v0#WorkloadIdentity": security_resources.#WorkloadIdentityResource
	}

	optionalResources: {}
	requiredTraits: {}
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

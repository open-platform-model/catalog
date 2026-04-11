package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	security_traits "opmodel.dev/opm/v1alpha1/traits/security@v1"
)

// ServiceAccountTransformer converts WorkloadIdentity traits to Kubernetes ServiceAccounts
#ServiceAccountTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/providers/kubernetes/transformers"
		version:     "v1"
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
		"opmodel.dev/opm/v1alpha1/traits/security/workload-identity@v1": security_traits.#WorkloadIdentityTrait
	}

	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_workloadIdentity: #component.spec.workloadIdentity

		output: (#ToK8sServiceAccount & {
			"in":    _workloadIdentity
			context: #context
		}).out
	}
}

package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1alpha1/resources/policy@v1"
)

// #PodDisruptionBudgetTransformer passes native Kubernetes PodDisruptionBudget resources through
// with OPM context applied (name prefix, namespace, labels).
#PodDisruptionBudgetTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "poddisruptionbudget-transformer"
		description: "Passes native Kubernetes PodDisruptionBudget resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "policy"
			"core.opmodel.dev/resource-type":     "poddisruptionbudget"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#PodDisruptionBudgetResource.metadata.fqn): res.#PodDisruptionBudgetResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_pdb:  #component.spec.poddisruptionbudget
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "policy/v1"
			kind:       "PodDisruptionBudget"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _pdb.metadata != _|_ {
					if _pdb.metadata.annotations != _|_ {
						annotations: _pdb.metadata.annotations
					}
				}
			}
			if _pdb.spec != _|_ {
				spec: _pdb.spec
			}
		}
	}
}

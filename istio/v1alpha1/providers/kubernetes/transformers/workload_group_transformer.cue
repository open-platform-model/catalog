package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/istio/v1alpha1/resources/network@v1"
)

#WorkloadGroupTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/istio/providers/kubernetes/transformers"
		version:     "v1"
		name:        "workload-group-transformer"
		description: "Passes native Istio WorkloadGroup resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "workload-group"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#WorkloadGroupResource.metadata.fqn): res.#WorkloadGroupResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_wg:   #component.spec.workloadGroup
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "networking.istio.io/v1"
			kind:       "WorkloadGroup"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _wg.metadata != _|_ {
					if _wg.metadata.annotations != _|_ {
						annotations: _wg.metadata.annotations
					}
				}
			}
			if _wg.spec != _|_ {
				spec: _wg.spec
			}
		}
	}
}

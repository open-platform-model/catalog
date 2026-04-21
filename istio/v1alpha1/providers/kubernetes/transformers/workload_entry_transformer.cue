package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/istio/v1alpha1/resources/network@v1"
)

#WorkloadEntryTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/istio/providers/kubernetes/transformers"
		version:     "v1"
		name:        "workload-entry-transformer"
		description: "Passes native Istio WorkloadEntry resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "workload-entry"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#WorkloadEntryResource.metadata.fqn): res.#WorkloadEntryResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_we:   #component.spec.workloadEntry
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "networking.istio.io/v1"
			kind:       "WorkloadEntry"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _we.metadata != _|_ {
					if _we.metadata.annotations != _|_ {
						annotations: _we.metadata.annotations
					}
				}
			}
			if _we.spec != _|_ {
				spec: _we.spec
			}
		}
	}
}

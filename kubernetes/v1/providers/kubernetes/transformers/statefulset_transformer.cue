package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1/resources/workload@v1"
)

// #StatefulSetTransformer passes native Kubernetes StatefulSet resources through
// with OPM context applied (name prefix, namespace, labels).
#StatefulSetTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "statefulset-transformer"
		description: "Passes native Kubernetes StatefulSet resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "statefulset"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#StatefulSetResource.metadata.fqn): res.#StatefulSetResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_sts:  #component.spec.statefulset
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _sts.metadata != _|_ {
					if _sts.metadata.annotations != _|_ {
						annotations: _sts.metadata.annotations
					}
				}
			}
			if _sts.spec != _|_ {
				spec: _sts.spec
			}
		}
	}
}

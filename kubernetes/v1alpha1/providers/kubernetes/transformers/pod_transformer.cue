package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1alpha1/resources/workload@v1"
)

// #PodTransformer passes native Kubernetes Pod resources through
// with OPM context applied (name prefix, namespace, labels).
#PodTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "pod-transformer"
		description: "Passes native Kubernetes Pod resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "pod"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#PodResource.metadata.fqn): res.#PodResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_pod:  #component.spec.pod
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "v1"
			kind:       "Pod"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _pod.metadata != _|_ {
					if _pod.metadata.annotations != _|_ {
						annotations: _pod.metadata.annotations
					}
				}
			}
			if _pod.spec != _|_ {
				spec: _pod.spec
			}
		}
	}
}

package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1alpha1/resources/policy@v1"
)

// #HorizontalPodAutoscalerTransformer passes native Kubernetes HPA resources through
// with OPM context applied (name prefix, namespace, labels).
#HorizontalPodAutoscalerTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "horizontalpodautoscaler-transformer"
		description: "Passes native Kubernetes HorizontalPodAutoscaler resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "policy"
			"core.opmodel.dev/resource-type":     "horizontalpodautoscaler"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#HorizontalPodAutoscalerResource.metadata.fqn): res.#HorizontalPodAutoscalerResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_hpa:  #component.spec.horizontalpodautoscaler
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "autoscaling/v2"
			kind:       "HorizontalPodAutoscaler"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _hpa.metadata != _|_ {
					if _hpa.metadata.annotations != _|_ {
						annotations: _hpa.metadata.annotations
					}
				}
			}
			if _hpa.spec != _|_ {
				spec: _hpa.spec
			}
		}
	}
}

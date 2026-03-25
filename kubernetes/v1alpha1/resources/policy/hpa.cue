package policy

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// HorizontalPodAutoscaler Resource Definition
/////////////////////////////////////////////////////////////////

// #HorizontalPodAutoscalerResource defines a native Kubernetes HPA v2 as an OPM resource.
// Use this to automatically scale workload replicas based on metrics.
#HorizontalPodAutoscalerResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/policy"
		version:     "v1"
		name:        "horizontalpodautoscaler"
		description: "A native Kubernetes HorizontalPodAutoscaler resource"
		labels: {
			"resource.opmodel.dev/category": "policy"
		}
	}

	#defaults: #HorizontalPodAutoscalerDefaults

	spec: close({horizontalpodautoscaler: schemas.#HorizontalPodAutoscalerSchema})
}

#HorizontalPodAutoscalerComponent: component.#Component & {
	#resources: {(#HorizontalPodAutoscalerResource.metadata.fqn): #HorizontalPodAutoscalerResource}
}

#HorizontalPodAutoscalerDefaults: schemas.#HorizontalPodAutoscalerSchema & {}

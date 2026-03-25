@if(test)

package transformers

// Test: minimal HorizontalPodAutoscaler with required fields
_testHorizontalPodAutoscalerMinimal: (#HorizontalPodAutoscalerTransformer.#transform & {
	#component: {
		metadata: name: "web-hpa"
		spec: horizontalpodautoscaler: {
			spec: {
				scaleTargetRef: {
					apiVersion: "apps/v1"
					kind:       "Deployment"
					name:       "web"
				}
				minReplicas: 1
				maxReplicas: 5
			}
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "web-hpa"}).out
}).output & {
	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      "my-release-web-hpa"
		namespace: "default"
	}
}

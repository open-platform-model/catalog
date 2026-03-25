@if(test)

package transformers

// Test: minimal PodDisruptionBudget with required fields
_testPodDisruptionBudgetMinimal: (#PodDisruptionBudgetTransformer.#transform & {
	#component: {
		metadata: name: "web-pdb"
		spec: poddisruptionbudget: {
			spec: selector: matchLabels: app: "web"
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "web-pdb"}).out
}).output & {
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "my-release-web-pdb"
		namespace: "default"
	}
}

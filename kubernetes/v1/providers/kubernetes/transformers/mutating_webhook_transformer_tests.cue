@if(test)

package transformers

// Test: minimal MutatingWebhookConfiguration — cluster-scoped, no namespace in output
_testMutatingWebhookConfigurationMinimal: (#MutatingWebhookConfigurationTransformer.#transform & {
	#component: {
		metadata: name: "app-mutator"
		spec: mutatingwebhookconfiguration: {}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "app-mutator"}).out
}).output & {
	apiVersion: "admissionregistration.k8s.io/v1"
	kind:       "MutatingWebhookConfiguration"
	metadata: name: "my-release-app-mutator"
}

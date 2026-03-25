@if(test)

package transformers

// Test: minimal ValidatingWebhookConfiguration — cluster-scoped, no namespace in output
_testValidatingWebhookConfigurationMinimal: (#ValidatingWebhookConfigurationTransformer.#transform & {
	#component: {
		metadata: name: "app-validator"
		spec: validatingwebhookconfiguration: {}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "app-validator"}).out
}).output & {
	apiVersion: "admissionregistration.k8s.io/v1"
	kind:       "ValidatingWebhookConfiguration"
	metadata: name: "my-release-app-validator"
}

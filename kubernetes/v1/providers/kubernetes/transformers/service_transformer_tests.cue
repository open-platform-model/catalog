@if(test)

package transformers

// Test: minimal Service with required fields
_testServiceMinimal: (#ServiceTransformer.#transform & {
	#component: {
		metadata: name: "web"
		spec: service: {
			spec: {
				selector: app: "web"
				ports: [{port: 80}]
			}
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "web"}).out
}).output & {
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "my-release-web"
		namespace: "default"
	}
}

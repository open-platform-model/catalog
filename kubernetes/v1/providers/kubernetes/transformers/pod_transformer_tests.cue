@if(test)

package transformers

// Test: minimal Pod with required fields
_testPodMinimal: (#PodTransformer.#transform & {
	#component: {
		metadata: name: "debug"
		spec: pod: {
			spec: {
				containers: [{
					name:  "debug"
					image: "busybox:latest"
				}]
				restartPolicy: "Never"
			}
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "debug"}).out
}).output & {
	apiVersion: "v1"
	kind:       "Pod"
	metadata: {
		name:      "my-release-debug"
		namespace: "default"
	}
}

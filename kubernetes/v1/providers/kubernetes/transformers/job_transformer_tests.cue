@if(test)

package transformers

// Test: minimal Job with required fields
_testJobMinimal: (#JobTransformer.#transform & {
	#component: {
		metadata: name: "migrate"
		spec: job: {
			spec: {
				template: {
					spec: {
						containers: [{
							name:  "migrate"
							image: "flyway:latest"
						}]
						restartPolicy: "Never"
					}
				}
			}
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "migrate"}).out
}).output & {
	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "my-release-migrate"
		namespace: "default"
	}
}

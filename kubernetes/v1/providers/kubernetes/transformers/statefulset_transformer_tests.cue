@if(test)

package transformers

// Test: minimal StatefulSet with required fields (serviceName is required)
_testStatefulSetMinimal: (#StatefulSetTransformer.#transform & {
	#component: {
		metadata: name: "db"
		spec: statefulset: {
			spec: {
				serviceName: "db"
				selector: matchLabels: app: "db"
				template: {
					metadata: labels: app: "db"
					spec: containers: [{
						name:  "db"
						image: "postgres:15"
					}]
				}
			}
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "db"}).out
}).output & {
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "my-release-db"
		namespace: "default"
	}
}

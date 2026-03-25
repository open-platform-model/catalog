@if(test)

package transformers

// Test: minimal DaemonSet with required fields
_testDaemonSetMinimal: (#DaemonSetTransformer.#transform & {
	#component: {
		metadata: name: "agent"
		spec: daemonset: {
			spec: {
				selector: matchLabels: app: "agent"
				template: {
					metadata: labels: app: "agent"
					spec: containers: [{
						name:  "agent"
						image: "datadog/agent:latest"
					}]
				}
			}
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "monitoring", component: "agent"}).out
}).output & {
	apiVersion: "apps/v1"
	kind:       "DaemonSet"
	metadata: {
		name:      "my-release-agent"
		namespace: "monitoring"
	}
}

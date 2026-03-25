@if(test)

package transformers

// Test: minimal Deployment with required fields
_testDeploymentMinimal: (#DeploymentTransformer.#transform & {
	#component: {
		metadata: name: "web"
		spec: deployment: {
			spec: {
				selector: matchLabels: app: "web"
				template: {
					metadata: labels: app: "web"
					spec: containers: [{
						name:  "web"
						image: "nginx:latest"
					}]
				}
			}
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "web"}).out
}).output & {
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "my-release-web"
		namespace: "default"
	}
}

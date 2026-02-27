@if(test)

package workload

import (
	tst "experiments.dev/test-framework/testkit"
)

#tests: tst.#Tests & {

	// =========================================================================
	// #ContainerResource — closedness of the resource definition
	// =========================================================================

	"#ContainerResource": [
		{
			name:       "valid resource metadata"
			definition: #ContainerResource
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Resource"
				metadata: {
					apiVersion:  "opmodel.dev/resources/workload@v0"
					name:        "container"
					description: "A container definition for workloads"
				}
			}
			assert: {
				valid:  true
				output: metadata: fqn: "opmodel.dev/resources/workload@v0#Container"
			}
		},
		{
			name:       "rejects extra field at root"
			definition: #ContainerResource
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Resource"
				metadata: {
					apiVersion: "opmodel.dev/resources/workload@v0"
					name:       "container"
				}
				bogus: "should-fail"
			}
			assert: valid: false
		},
		{
			name:       "rejects extra field in metadata"
			definition: #ContainerResource
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Resource"
				metadata: {
					apiVersion: "opmodel.dev/resources/workload@v0"
					name:       "container"
					bogus:      "should-fail"
				}
			}
			assert: valid: false
		},
	]

	// =========================================================================
	// #Container — component closedness (spec: close({_allFields}))
	// =========================================================================

	"#Container": [
		{
			name:       "valid container component"
			definition: #Container
			input: {
				metadata: {
					name: "my-app"
					labels: "core.opmodel.dev/workload-type": "stateless"
				}
				spec: container: {
					name:  "main"
					image: "nginx:latest"
				}
			}
			assert: valid: true
		},
		{
			name:       "valid with ports and env"
			definition: #Container
			input: {
				metadata: {
					name: "web-server"
					labels: "core.opmodel.dev/workload-type": "stateless"
				}
				spec: container: {
					name:  "web"
					image: "nginx:1.25"
					ports: http: targetPort: 8080
					env: APP_ENV: value:     "production"
				}
			}
			assert: valid: true
		},
		{
			name:       "rejects extra field in spec (closedness)"
			definition: #Container
			input: {
				metadata: {
					name: "my-app"
					labels: "core.opmodel.dev/workload-type": "stateless"
				}
				spec: {
					container: {
						name:  "main"
						image: "nginx:latest"
					}
					bogus: "should-fail"
				}
			}
			assert: valid: false
		},
		{
			name:       "rejects missing workload-type label"
			definition: #Container
			input: {
				metadata: name: "my-app"
				spec: container: {
					name:  "main"
					image: "nginx:latest"
				}
			}
			assert: valid: false
		},
		{
			name:       "rejects invalid workload-type"
			definition: #Container
			input: {
				metadata: {
					name: "my-app"
					labels: "core.opmodel.dev/workload-type": "invalid"
				}
				spec: container: {
					name:  "main"
					image: "nginx:latest"
				}
			}
			assert: valid: false
		},
	]

	// =========================================================================
	// #ContainerDefaults
	// =========================================================================

	"#ContainerDefaults": [
		{
			name:       "provides default imagePullPolicy"
			definition: #ContainerDefaults
			input: {
				name:  "main"
				image: "nginx:latest"
			}
			assert: output: imagePullPolicy: "IfNotPresent"
		},
		{
			name:       "allows overriding imagePullPolicy"
			definition: #ContainerDefaults
			input: {
				name:            "main"
				image:           "nginx:latest"
				imagePullPolicy: "Always"
			}
			assert: output: imagePullPolicy: "Always"
		},
	]
}

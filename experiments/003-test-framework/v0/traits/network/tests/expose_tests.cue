@if(test)

package network

import (
	tst "experiments.dev/test-framework/testkit"
)

#tests: tst.#Tests & {

	// =========================================================================
	// #ExposeTrait — closedness of the trait definition
	// =========================================================================

	"#ExposeTrait": [
		{
			name:       "valid trait metadata"
			definition: #ExposeTrait
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Trait"
				metadata: {
					apiVersion:  "opmodel.dev/traits/network@v0"
					name:        "expose"
					description: "A trait to expose a workload via a service"
				}
			}
			assert: {
				valid:  true
				output: metadata: fqn: "opmodel.dev/traits/network@v0#Expose"
			}
		},
		{
			name:       "rejects extra field at root"
			definition: #ExposeTrait
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Trait"
				metadata: {
					apiVersion: "opmodel.dev/traits/network@v0"
					name:       "expose"
				}
				bogus: "should-fail"
			}
			assert: valid: false
		},
		{
			name:       "rejects extra field in metadata"
			definition: #ExposeTrait
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Trait"
				metadata: {
					apiVersion: "opmodel.dev/traits/network@v0"
					name:       "expose"
					bogus:      "should-fail"
				}
			}
			assert: valid: false
		},
	]

	// =========================================================================
	// #Expose — component with expose trait (spec closedness)
	// =========================================================================

	"#Expose": [
		{
			name:       "valid expose component"
			definition: #Expose
			input: {
				metadata: name: "my-app"
				spec: expose: {
					type: "ClusterIP"
					ports: http: targetPort: 8080
				}
			}
			assert: valid: true
		},
		{
			name:       "valid with NodePort type"
			definition: #Expose
			input: {
				metadata: name: "my-app"
				spec: expose: {
					type: "NodePort"
					ports: http: targetPort: 8080
				}
			}
			assert: output: spec: expose: type: "NodePort"
		},
		{
			name:       "rejects extra field in spec (closedness)"
			definition: #Expose
			input: {
				metadata: name: "my-app"
				spec: {
					expose: {
						type: "ClusterIP"
						ports: http: targetPort: 8080
					}
					bogus: "should-fail"
				}
			}
			assert: valid: false
		},
		{
			name:       "rejects invalid service type"
			definition: #Expose
			input: {
				metadata: name: "my-app"
				spec: expose: {
					type: "ExternalName"
					ports: http: targetPort: 8080
				}
			}
			assert: valid: false
		},
	]

	// =========================================================================
	// #ExposeDefaults
	// =========================================================================

	"#ExposeDefaults": [
		{
			name:       "provides default type"
			definition: #ExposeDefaults
			input: {
				ports: http: targetPort: 8080
			}
			assert: output: type: "ClusterIP"
		},
	]
}

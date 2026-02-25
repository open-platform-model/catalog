@if(test)

package network

import (
	tst "experiments.dev/test-framework/testkit"
)

#tests: tst.#Tests & {

	// =========================================================================
	// #ExposeTrait — closedness of the trait definition
	// =========================================================================

	exposeTrait: [
		{
			name:       "valid trait metadata"
			definition: "#ExposeTrait"
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
				valid:    true
				concrete: false
				fields: {
					"metadata.fqn": equals: "opmodel.dev/traits/network@v0#Expose"
				}
			}
		},
		{
			name:       "rejects extra field at root"
			definition: "#ExposeTrait"
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
			definition: "#ExposeTrait"
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

	exposeComponent: [
		{
			name:       "valid expose component"
			definition: "#Expose"
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
			definition: "#Expose"
			input: {
				metadata: name: "my-app"
				spec: expose: {
					type: "NodePort"
					ports: http: targetPort: 8080
				}
			}
			assert: {
				valid: true
				fields: {
					"spec.expose.type": equals: "NodePort"
				}
			}
		},
		{
			name:       "rejects extra field in spec (closedness)"
			definition: "#Expose"
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
			definition: "#Expose"
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

	exposeDefaults: [
		{
			name:       "provides default type"
			definition: "#ExposeDefaults"
			input: {
				ports: http: targetPort: 8080
			}
			assert: {
				valid: true
				fields: type: equals: "ClusterIP"
			}
		},
	]
}

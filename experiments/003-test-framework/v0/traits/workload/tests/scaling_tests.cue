@if(test)

package workload

import (
	tst "experiments.dev/test-framework/testkit"
)

#tests: tst.#Tests & {

	// =========================================================================
	// #ScalingTrait — closedness of the trait definition
	// =========================================================================

	scalingTrait: [
		{
			name:       "valid trait metadata"
			definition: "#ScalingTrait"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Trait"
				metadata: {
					apiVersion:  "opmodel.dev/traits/workload@v0"
					name:        "scaling"
					description: "A trait to specify scaling behavior for a workload"
					labels: "core.opmodel.dev/category": "workload"
				}
			}
			assert: {
				valid:    true
				concrete: false // #spec, #defaults, appliesTo are inconcrete at trait level
				fields: {
					"metadata.fqn": equals: "opmodel.dev/traits/workload@v0#Scaling"
				}
			}
		},
		{
			name:       "rejects extra field at root"
			definition: "#ScalingTrait"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Trait"
				metadata: {
					apiVersion: "opmodel.dev/traits/workload@v0"
					name:       "scaling"
				}
				bogus: "should-fail"
			}
			assert: valid: false
		},
		{
			name:       "rejects extra field in metadata"
			definition: "#ScalingTrait"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Trait"
				metadata: {
					apiVersion: "opmodel.dev/traits/workload@v0"
					name:       "scaling"
					bogus:      "should-fail"
				}
			}
			assert: valid: false
		},
	]

	// =========================================================================
	// #Scaling — component with scaling trait (spec closedness)
	// =========================================================================

	scalingComponent: [
		{
			name:       "valid scaling component with defaults"
			definition: "#Scaling"
			input: {
				metadata: name: "my-app"
				spec: scaling: count: 1
			}
			assert: valid: true
		},
		{
			name:       "valid scaling component with count"
			definition: "#Scaling"
			input: {
				metadata: name: "my-app"
				spec: scaling: count: 3
			}
			assert: {
				valid: true
				fields: {
					"spec.scaling.count": equals: 3
				}
			}
		},
		{
			name:       "rejects extra field in spec (closedness)"
			definition: "#Scaling"
			input: {
				metadata: name: "my-app"
				spec: {
					scaling: count: 1
					bogus: "should-fail"
				}
			}
			assert: valid: false
		},
		{
			name:       "rejects count below minimum"
			definition: "#Scaling"
			input: {
				metadata: name: "my-app"
				spec: scaling: count: 0
			}
			assert: valid: false
		},
		{
			name:       "rejects count above maximum"
			definition: "#Scaling"
			input: {
				metadata: name: "my-app"
				spec: scaling: count: 1001
			}
			assert: valid: false
		},
	]

	// =========================================================================
	// #ScalingDefaults
	// =========================================================================

	scalingDefaults: [
		{
			name:       "provides default count"
			definition: "#ScalingDefaults"
			input: {}
			assert: {
				valid: true
				fields: count: equals: 1
			}
		},
	]
}

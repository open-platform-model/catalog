@if(test)

package core

import (
	tst "experiments.dev/test-framework/testkit"
)

#tests: tst.#Tests & {

	// =========================================================================
	// #NameType
	// =========================================================================

	nameType: [
		{
			name:       "simple"
			definition: "#NameType"
			input:      "my-app"
			assert: valid: true
		},
		{
			name:       "single char"
			definition: "#NameType"
			input:      "a"
			assert: valid: true
		},
		{
			name:       "max length 63"
			definition: "#NameType"
			input:      "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
			assert: valid: true
		},
		{
			name:       "rejects uppercase"
			definition: "#NameType"
			input:      "MyApp"
			assert: valid: false
		},
		{
			name:       "rejects leading hyphen"
			definition: "#NameType"
			input:      "-my-app"
			assert: valid: false
		},
		{
			name:       "rejects trailing hyphen"
			definition: "#NameType"
			input:      "my-app-"
			assert: valid: false
		},
		{
			name:       "rejects empty"
			definition: "#NameType"
			input:      ""
			assert: valid: false
		},
		{
			name:       "rejects too long"
			definition: "#NameType"
			input:      "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
			assert: valid: false
		},
	]

	// =========================================================================
	// #APIVersionType
	// =========================================================================

	apiVersionType: [
		{
			name:       "simple"
			definition: "#APIVersionType"
			input:      "opmodel.dev/core@v0"
			assert: valid: true
		},
		{
			name:       "nested path"
			definition: "#APIVersionType"
			input:      "opmodel.dev/resources/workload@v0"
			assert: valid: true
		},
		{
			name:       "rejects missing version"
			definition: "#APIVersionType"
			input:      "opmodel.dev/core"
			assert: valid: false
		},
		{
			name:       "rejects uppercase"
			definition: "#APIVersionType"
			input:      "Opmodel.dev/core@v0"
			assert: valid: false
		},
	]

	// =========================================================================
	// #FQNType
	// =========================================================================

	fqnType: [
		{
			name:       "simple"
			definition: "#FQNType"
			input:      "opmodel.dev@v0#Container"
			assert: valid: true
		},
		{
			name:       "with path"
			definition: "#FQNType"
			input:      "opmodel.dev/resources/workload@v0#Container"
			assert: valid: true
		},
		{
			name:       "rejects lowercase definition name"
			definition: "#FQNType"
			input:      "opmodel.dev@v0#container"
			assert: valid: false
		},
		{
			name:       "rejects missing hash"
			definition: "#FQNType"
			input:      "opmodel.dev@v0Container"
			assert: valid: false
		},
	]

	// =========================================================================
	// #Resource
	// =========================================================================

	resource: [
		{
			name:       "valid minimal resource"
			definition: "#Resource"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Resource"
				metadata: {
					apiVersion: "opmodel.dev/resources/workload@v0"
					name:       "container"
				}
			}
			assert: {
				valid:    true
				concrete: false // #spec is intentionally inconcrete at core level
				fields: {
					"metadata.fqn": equals: "opmodel.dev/resources/workload@v0#Container"
				}
			}
		},
		{
			name:       "valid resource with description"
			definition: "#Resource"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Resource"
				metadata: {
					apiVersion:  "opmodel.dev/resources/config@v0"
					name:        "config-maps"
					description: "ConfigMaps resource"
				}
			}
			assert: {
				valid:    true
				concrete: false
				fields: {
					"metadata.fqn": equals: "opmodel.dev/resources/config@v0#ConfigMaps"
				}
			}
		},
		{
			name:       "valid resource with labels"
			definition: "#Resource"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Resource"
				metadata: {
					apiVersion: "opmodel.dev/resources/workload@v0"
					name:       "container"
					labels: "core.opmodel.dev/workload-type": "stateless"
				}
			}
			assert: {
				valid:    true
				concrete: false
			}
		},
		{
			name:       "rejects missing metadata.name"
			definition: "#Resource"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Resource"
				metadata: apiVersion: "opmodel.dev/resources/workload@v0"
			}
			assert: valid: false
		},
		{
			name:       "rejects missing metadata.apiVersion"
			definition: "#Resource"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Resource"
				metadata: name: "container"
			}
			assert: valid: false
		},
		{
			name:       "rejects wrong kind"
			definition: "#Resource"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Trait"
				metadata: {
					apiVersion: "opmodel.dev/resources/workload@v0"
					name:       "container"
				}
			}
			assert: valid: false
		},
		{
			name:       "rejects extra field at root"
			definition: "#Resource"
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
			definition: "#Resource"
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
	// #Trait
	// =========================================================================

	trait: [
		{
			name:       "valid minimal trait"
			definition: "#Trait"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Trait"
				metadata: {
					apiVersion: "opmodel.dev/traits/workload@v0"
					name:       "scaling"
				}
				appliesTo: []
			}
			assert: {
				valid:    true
				concrete: true // #spec is intentionally inconcrete at core level
				fields: {
					"metadata.fqn": equals: "opmodel.dev/traits/workload@v0#Scaling"
				}
			}
		},
		{
			name:       "rejects wrong kind"
			definition: "#Trait"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Resource"
				metadata: {
					apiVersion: "opmodel.dev/traits/workload@v0"
					name:       "scaling"
				}
				appliesTo: []
			}
			assert: valid: false
		},
		{
			name:       "rejects missing appliesTo"
			definition: "#Trait"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Trait"
				metadata: {
					apiVersion: "opmodel.dev/traits/workload@v0"
					name:       "scaling"
				}
			}
			assert: valid: false
		},
		{
			name:       "rejects extra field at root"
			definition: "#Trait"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Trait"
				metadata: {
					apiVersion: "opmodel.dev/traits/workload@v0"
					name:       "scaling"
				}
				appliesTo: []
				bogus: "should-fail"
			}
			assert: valid: false
		},
		{
			name:       "rejects extra field in metadata"
			definition: "#Trait"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Trait"
				metadata: {
					apiVersion: "opmodel.dev/traits/workload@v0"
					name:       "scaling"
					bogus:      "should-fail"
				}
				appliesTo: []
			}
			assert: valid: false
		},
	]

	// =========================================================================
	// #Blueprint
	// =========================================================================

	blueprint: [
		{
			name:       "valid minimal blueprint"
			definition: "#Blueprint"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Blueprint"
				metadata: {
					apiVersion: "opmodel.dev/blueprints@v0"
					name:       "stateless-workload"
				}
				composedResources: []
			}
			assert: {
				valid:    true
				concrete: false // #spec is intentionally inconcrete at core level
				fields: {
					"metadata.fqn": equals: "opmodel.dev/blueprints@v0#StatelessWorkload"
				}
			}
		},
		{
			name:       "rejects missing composedResources"
			definition: "#Blueprint"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Blueprint"
				metadata: {
					apiVersion: "opmodel.dev/blueprints@v0"
					name:       "stateless-workload"
				}
			}
			assert: valid: false
		},
		{
			name:       "rejects extra field at root"
			definition: "#Blueprint"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Blueprint"
				metadata: {
					apiVersion: "opmodel.dev/blueprints@v0"
					name:       "stateless-workload"
				}
				composedResources: []
				bogus: "should-fail"
			}
			assert: valid: false
		},
	]

	// =========================================================================
	// #PolicyRule
	// =========================================================================

	policyRule: [
		{
			name:       "valid minimal policy rule"
			definition: "#PolicyRule"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "PolicyRule"
				metadata: {
					apiVersion: "opmodel.dev/policies/network@v0"
					name:       "network-rules"
				}
				enforcement: {
					mode:        "deployment"
					onViolation: "block"
				}
			}
			assert: {
				valid:    true
				concrete: false // #spec is intentionally inconcrete at core level
				fields: {
					"metadata.fqn": equals: "opmodel.dev/policies/network@v0#NetworkRules"
				}
			}
		},
		{
			name:       "valid policy rule with runtime enforcement"
			definition: "#PolicyRule"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "PolicyRule"
				metadata: {
					apiVersion: "opmodel.dev/policies/security@v0"
					name:       "encryption"
				}
				enforcement: {
					mode:        "both"
					onViolation: "warn"
				}
			}
			assert: {
				valid:    true
				concrete: false
			}
		},
		{
			name:       "rejects invalid enforcement mode"
			definition: "#PolicyRule"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "PolicyRule"
				metadata: {
					apiVersion: "opmodel.dev/policies/network@v0"
					name:       "network-rules"
				}
				enforcement: {
					mode:        "invalid"
					onViolation: "block"
				}
			}
			assert: valid: false
		},
		{
			name:       "rejects extra field at root"
			definition: "#PolicyRule"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "PolicyRule"
				metadata: {
					apiVersion: "opmodel.dev/policies/network@v0"
					name:       "network-rules"
				}
				enforcement: {
					mode:        "deployment"
					onViolation: "block"
				}
				bogus: "should-fail"
			}
			assert: valid: false
		},
	]

	// =========================================================================
	// #KebabToPascal
	// =========================================================================

	kebabToPascal: [
		{
			name:       "single word"
			definition: "#KebabToPascal"
			input: "in": "container"
			assert: {
				valid: true
				fields: out: equals: "Container"
			}
		},
		{
			name:       "two words"
			definition: "#KebabToPascal"
			input: "in": "config-maps"
			assert: {
				valid: true
				fields: out: equals: "ConfigMaps"
			}
		},
		{
			name:       "three words"
			definition: "#KebabToPascal"
			input: "in": "stateless-workload-type"
			assert: {
				valid: true
				fields: out: equals: "StatelessWorkloadType"
			}
		},
	]
}

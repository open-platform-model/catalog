@if(test)

package core

// =============================================================================
// Blueprint Definition Tests
// =============================================================================

// Helper resource for blueprint composition
_testBlueprintResource: #Resource & {
	metadata: {
		apiVersion: "test.dev/resources@v0"
		name:       "bp-resource"
	}
	#spec: bpResource: {
		name:  string
		image: string
	}
}

// Helper trait for blueprint composition
_testBlueprintTrait: #Trait & {
	metadata: {
		apiVersion: "test.dev/traits@v0"
		name:       "bp-trait"
	}
	#spec: bpTrait: {
		count: int
	}
	appliesTo: [_testBlueprintResource]
}

// Test: minimal valid blueprint (only required fields)
_testBlueprintMinimal: #Blueprint & {
	metadata: {
		apiVersion: "test.dev/blueprints@v0"
		name:       "minimal-blueprint"
	}
	composedResources: [_testBlueprintResource]
	#spec: minimalBlueprint: {
		name:  string
		image: string
	}
}

// Test: blueprint with all optional fields
_testBlueprintFull: #Blueprint & {
	metadata: {
		apiVersion:  "test.dev/blueprints@v0"
		name:        "full-blueprint"
		description: "A fully specified test blueprint"
		labels: {
			"test.dev/category":              "workload"
			"core.opmodel.dev/workload-type": "stateless"
		}
		annotations: {
			"test.dev/note": "test annotation"
		}
	}
	composedResources: [_testBlueprintResource]
	composedTraits: [_testBlueprintTrait]
	#spec: fullBlueprint: {
		name:  string
		image: string
		count: int
	}
}

// Test: blueprint FQN computation
_testBlueprintFQN: #Blueprint & {
	metadata: {
		apiVersion: "test.dev/blueprints@v0"
		name:       "stateless-workload"
		fqn:        "test.dev/blueprints@v0#StatelessWorkload"
	}
	composedResources: [_testBlueprintResource]
	#spec: statelessWorkload: {
		data: string
	}
}

// Test: blueprint with multiple composed resources
_testBlueprintMultiResource: #Blueprint & {
	metadata: {
		apiVersion: "test.dev/blueprints@v0"
		name:       "multi-resource"
	}
	composedResources: [_testBlueprintResource, _testBlueprintResource]
	composedTraits: [_testBlueprintTrait]
	#spec: multiResource: {
		data: string
	}
}

// Negative tests moved to testdata/*.yaml files

@if(test)

package core

// =============================================================================
// Trait Definition Tests
// =============================================================================

// Helper resource for trait appliesTo references
_testTraitTargetResource: #Resource & {
	metadata: {
		apiVersion: "test.dev/resources@v0"
		name:       "target-resource"
	}
	#spec: targetResource: {
		field1: string
	}
}

// Test: minimal valid trait
_testTraitMinimal: #Trait & {
	metadata: {
		apiVersion: "test.dev/traits@v0"
		name:       "minimal-trait"
	}
	#spec: minimalTrait: {
		value: int
	}
	appliesTo: [_testTraitTargetResource]
}

// Test: trait with all optional fields
_testTraitFull: #Trait & {
	metadata: {
		apiVersion:  "test.dev/traits@v0"
		name:        "full-trait"
		description: "A fully specified test trait"
		labels: {
			"test.dev/category": "testing"
		}
		annotations: {
			"test.dev/note": "test annotation"
		}
	}
	#spec: fullTrait: {
		enabled: bool
		count:   int
	}
	appliesTo: [_testTraitTargetResource]
}

// Test: trait FQN computation
_testTraitFQN: #Trait & {
	metadata: {
		apiVersion: "test.dev/traits@v0"
		name:       "scaling"
		fqn:        "test.dev/traits@v0#Scaling"
	}
	#spec: scaling: {
		count: int
	}
	appliesTo: [_testTraitTargetResource]
}

// Test: trait with multiple appliesTo resources
_testTraitMultiAppliesTo: #Trait & {
	metadata: {
		apiVersion: "test.dev/traits@v0"
		name:       "multi-applies"
	}
	#spec: multiApplies: {
		setting: string
	}
	appliesTo: [_testTraitTargetResource, _testTraitTargetResource]
}

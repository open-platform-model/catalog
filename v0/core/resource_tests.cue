@if(test)

package core

// =============================================================================
// Resource Definition Tests
// =============================================================================

// Test: minimal valid resource (only required fields)
_testResourceMinimal: #Resource & {
	metadata: {
		apiVersion: "test.dev/resources@v0"
		name:       "minimal-resource"
	}
	#spec: minimalResource: {
		field1: string
	}
}

// Test: resource with all optional fields populated
_testResourceFull: #Resource & {
	metadata: {
		apiVersion:  "test.dev/resources@v0"
		name:        "full-resource"
		description: "A fully specified test resource"
		labels: {
			"test.dev/category": "testing"
		}
		annotations: {
			"test.dev/note": "test annotation"
		}
	}
	#spec: fullResource: {
		field1: string
		field2: int
	}
}

// Test: resource name with multiple hyphens
_testResourceMultiHyphen: #Resource & {
	metadata: {
		apiVersion: "test.dev/resources@v0"
		name:       "my-multi-word-resource"
	}
	#spec: myMultiWordResource: {
		data: string
	}
}

// Test: resource with single character name
_testResourceSingleChar: #Resource & {
	metadata: {
		apiVersion: "test.dev/resources@v0"
		name:       "x"
	}
	#spec: x: {
		data: string
	}
}

// Test: FQN is correctly computed from apiVersion + PascalCase(name)
_testResourceFQN: #Resource & {
	metadata: {
		apiVersion: "test.dev/resources@v0"
		name:       "my-resource"
		fqn:        "test.dev/resources@v0#MyResource"
	}
	#spec: myResource: {
		data: string
	}
}

// Test: resource with nested path in apiVersion
_testResourceNestedAPI: #Resource & {
	metadata: {
		apiVersion: "opmodel.dev/resources/workload@v0"
		name:       "container"
	}
	#spec: container: {
		name:  string
		image: string
	}
}

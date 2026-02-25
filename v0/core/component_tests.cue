@if(test)

package core

// =============================================================================
// Component Definition Tests
// =============================================================================

// Helper resource for component tests
_testCompResource: #Resource & {
	metadata: {
		apiVersion:  "test.dev/resources@v0"
		name:        "container"
		description: "Test container resource"
		labels: {
			"core.opmodel.dev/workload-type": "stateless"
		}
	}
	#spec: container: {
		name!:  #NameType
		image!: string
	}
}

// Helper trait for component tests
_testCompTrait: #Trait & {
	metadata: {
		apiVersion:  "test.dev/traits@v0"
		name:        "scaling"
		description: "Test scaling trait"
	}
	#spec: scaling: {
		count: int & >=1 & <=1000 | *1
	}
	appliesTo: [_testCompResource]
}

// Test: minimal component with one resource
_testComponentMinimalResource: #Component & {
	metadata: {
		name: "minimal-component"
	}
	#resources: {
		(_testCompResource.metadata.fqn): _testCompResource
	}
	spec: {
		container: {
			name:  "test"
			image: "nginx:latest"
		}
	}
}

// Test: component with resource and trait
_testComponentWithTrait: #Component & {
	metadata: {
		name: "component-with-trait"
	}
	#resources: {
		(_testCompResource.metadata.fqn): _testCompResource
	}
	#traits: {
		(_testCompTrait.metadata.fqn): _testCompTrait
	}
	spec: {
		container: {
			name:  "test"
			image: "nginx:latest"
		}
		scaling: count: 3
	}
}

// Test: component labels are inherited from resources
_testComponentLabelInheritance: #Component & {
	metadata: {
		name: "label-test"
		// This label should be inherited from the resource
		labels: "core.opmodel.dev/workload-type": "stateless"
	}
	#resources: {
		(_testCompResource.metadata.fqn): _testCompResource
	}
	spec: {
		container: {
			name:  "test"
			image: "nginx:latest"
		}
	}
}

// Test: component with custom labels merged with inherited ones
_testComponentCustomLabels: #Component & {
	metadata: {
		name: "custom-labels"
		labels: {
			"custom.dev/tier": "frontend"
			// workload-type inherited from resource
		}
	}
	#resources: {
		(_testCompResource.metadata.fqn): _testCompResource
	}
	spec: {
		container: {
			name:  "test"
			image: "nginx:latest"
		}
	}
}

// Helper resource #2 for multi-resource tests
_testCompResource2: #Resource & {
	metadata: {
		apiVersion: "test.dev/resources@v0"
		name:       "volume"
	}
	#spec: volume: {
		name!: #NameType
		size!: string
	}
}

// Test: component with multiple resources
_testComponentMultiResource: #Component & {
	metadata: {
		name: "multi-resource"
	}
	#resources: {
		(_testCompResource.metadata.fqn):  _testCompResource
		(_testCompResource2.metadata.fqn): _testCompResource2
	}
	spec: {
		container: {
			name:  "app"
			image: "app:latest"
		}
		volume: {
			name: "data"
			size: "10Gi"
		}
	}
}

// Negative tests moved to testdata/*.yaml files

@if(test)

package core

// Helper resource for transformer tests
_testTransformerResource: #Resource & {
	metadata: {
		apiVersion: "test.dev/resources@v0"
		name:       "test-resource"
	}
	#spec: testResource: {
		image: string
	}
	#defaults: testResource: {
		image: "nginx"
	}
}

// Helper trait for transformer tests
_testTransformerTrait: #Trait & {
	metadata: {
		apiVersion: "test.dev/traits@v0"
		name:       "test-trait"
	}
	appliesTo: [_testTransformerResource]
	#spec: testTrait: {
		count: int & >=1
	}
	#defaults: testTrait: {
		count: 1
	}
}

// #Transformer Tests

_testTransformerMinimal: #Transformer & {
	apiVersion: "opmodel.dev/core/v0"
	kind:       "Transformer"
	metadata: {
		apiVersion:  "test.dev/transformers@v0"
		name:        "test-transformer"
		description: "Test transformer"
	}
	requiredResources: {}
	requiredTraits: {}
	optionalResources: {}
	optionalTraits: {}
	#transform: {
		#component: _
		#context:   #TransformerContext
		output: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
		}
	}
}

_testTransformerFull: #Transformer & {
	apiVersion: "opmodel.dev/core/v0"
	kind:       "Transformer"
	metadata: {
		apiVersion:  "test.dev/transformers@v0"
		name:        "deployment-transformer"
		description: "Transforms stateless workloads to Deployments"
		labels: {
			"core.opmodel.dev/platform": "kubernetes"
		}
		annotations: {
			"docs.opmodel.dev/url": "https://docs.example.com"
		}
	}
	requiredLabels: {
		"core.opmodel.dev/workload-type": "stateless"
	}
	optionalLabels: {
		"core.opmodel.dev/replicas": "1"
	}
	requiredResources: {
		"test.dev/resources@v0#TestResource": _testTransformerResource
	}
	requiredTraits: {
		"test.dev/traits@v0#TestTrait": _testTransformerTrait
	}
	optionalResources: {}
	optionalTraits: {}
	#transform: {
		#component: _
		#context:   #TransformerContext
		output: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			metadata: name: #context.name
		}
	}
}

_testTransformerFQN: #Transformer & {
	apiVersion: "opmodel.dev/core/v0"
	kind:       "Transformer"
	metadata: {
		apiVersion:  "test.dev/transformers@v0"
		name:        "my-transformer"
		description: "Test FQN computation"
		fqn:         "test.dev/transformers@v0#MyTransformer"
	}
	requiredResources: {}
	requiredTraits: {}
	optionalResources: {}
	optionalTraits: {}
	#transform: {
		#component: _
		#context:   #TransformerContext
		output: {}
	}
}

// #TransformerContext Tests

_testTransformerContextMinimal: #TransformerContext & {
	#moduleReleaseMetadata: {
		name:      "myapp"
		namespace: "production"
		fqn:       "test.dev/modules@v0#MyApp"
		version:   "1.0.0"
		uuid:      "550e8400-e29b-41d4-a716-446655440000"
	}
	#componentMetadata: {
		name: "web"
	}
	name:      "myapp"
	namespace: "production"
}

_testTransformerContextLabelInheritance: #TransformerContext & {
	#moduleReleaseMetadata: {
		name:      "myapp"
		namespace: "production"
		fqn:       "test.dev/modules@v0#MyApp"
		version:   "1.0.0"
		uuid:      "550e8400-e29b-41d4-a716-446655440000"
		labels: {
			"env": "production"
		}
		annotations: {
			"team": "platform"
		}
	}
	#componentMetadata: {
		name: "web"
		labels: {
			"app": "frontend"
		}
		annotations: {
			"owner": "web-team"
		}
	}
	name:      "myapp"
	namespace: "production"
	labels: {
		"env":                          "production"
		"app":                          "frontend"
		"app.kubernetes.io/name":       "web"
		"app.kubernetes.io/managed-by": "open-platform-model"
		"app.kubernetes.io/instance":   "web"
		"app.kubernetes.io/version":    "1.0.0"
	}
	annotations: {
		"team":  "platform"
		"owner": "web-team"
	}
}

// #Matches Tests

// Helper component for matching tests
_testMatchComponent: #Component & {
	metadata: {
		name: "test-component"
		labels: {
			"core.opmodel.dev/workload-type": "stateless"
		}
	}
	#resources: {
		"test.dev/resources@v0#TestResource": _testTransformerResource
	}
	#traits: {
		"test.dev/traits@v0#TestTrait": _testTransformerTrait
	}
	spec: {
		testResource: {
			image: "nginx"
		}
		testTrait: {
			count: 3
		}
	}
}

_testMatchesSuccess: (#Matches & {
	transformer: _testTransformerFull
	component:   _testMatchComponent
}).result == true

_testMatchesMissingLabel: (#Matches & {
	transformer: _testTransformerFull
	component: #Component & {
		metadata: {
			name: "test-component"
			labels: {
				"wrong.label": "value"
			}
		}
		#resources: {
			"test.dev/resources@v0#TestResource": _testTransformerResource
		}
		#traits: {
			"test.dev/traits@v0#TestTrait": _testTransformerTrait
		}
		spec: {}
	}
}).result == false

_testMatchesMissingResource: (#Matches & {
	transformer: _testTransformerFull
	component: #Component & {
		metadata: {
			name: "test-component"
			labels: {
				"core.opmodel.dev/workload-type": "stateless"
			}
		}
		#resources: {
			"other.dev/resources@v0#OtherResource": _testTransformerResource
		}
		#traits: {
			"test.dev/traits@v0#TestTrait": _testTransformerTrait
		}
		spec: {}
	}
}).result == false

_testMatchesMissingTrait: (#Matches & {
	transformer: _testTransformerFull
	component: #Component & {
		metadata: {
			name: "test-component"
			labels: {
				"core.opmodel.dev/workload-type": "stateless"
			}
		}
		#resources: {
			"test.dev/resources@v0#TestResource": _testTransformerResource
		}
		#traits: {}
		spec: {}
	}
}).result == false

_testMatchesNoRequirements: (#Matches & {
	transformer: _testTransformerMinimal
	component:   _testMatchComponent
}).result == true

@if(test)

package core

// Helper transformers for provider tests
_testProviderTransformer1: #Transformer & {
	apiVersion: "opmodel.dev/core/v0"
	kind:       "Transformer"
	metadata: {
		apiVersion:  "test.dev/transformers@v0"
		name:        "deployment-transformer"
		description: "Test transformer 1"
	}
	requiredLabels: {
		"core.opmodel.dev/workload-type": "stateless"
	}
	requiredResources: {
		"test.dev/resources@v0#Container": _testTransformerResource
	}
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

_testProviderTransformer2: #Transformer & {
	apiVersion: "opmodel.dev/core/v0"
	kind:       "Transformer"
	metadata: {
		apiVersion:  "test.dev/transformers@v0"
		name:        "statefulset-transformer"
		description: "Test transformer 2"
	}
	requiredLabels: {
		"core.opmodel.dev/workload-type": "stateful"
	}
	requiredResources: {
		"test.dev/resources@v0#Container": _testTransformerResource
	}
	requiredTraits: {}
	optionalResources: {}
	optionalTraits: {}
	#transform: {
		#component: _
		#context:   #TransformerContext
		output: {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
		}
	}
}

// #Provider Tests

_testProviderMinimal: #Provider & {
	apiVersion: "core.opmodel.dev/v0"
	kind:       "Provider"
	metadata: {
		name:        "test-provider"
		description: "Test provider"
		version:     "1.0.0"
		minVersion:  "1.0.0"
	}
	transformers: {}
}

_testProviderFull: #Provider & {
	apiVersion: "core.opmodel.dev/v0"
	kind:       "Provider"
	metadata: {
		name:        "kubernetes-provider"
		description: "Kubernetes platform provider"
		version:     "1.0.0"
		minVersion:  "1.0.0"
		labels: {
			"core.opmodel.dev/format": "kubernetes"
		}
	}
	transformers: {
		"test.dev/transformers@v0#DeploymentTransformer":  _testProviderTransformer1
		"test.dev/transformers@v0#StatefulsetTransformer": _testProviderTransformer2
	}
}

_testProviderDeclaredResources: #Provider & {
	apiVersion: "core.opmodel.dev/v0"
	kind:       "Provider"
	metadata: {
		name:        "test-provider"
		description: "Test provider"
		version:     "1.0.0"
		minVersion:  "1.0.0"
	}
	transformers: {
		"test.dev/transformers@v0#DeploymentTransformer": _testProviderTransformer1
	}
	#declaredResources: ["test.dev/resources@v0#Container"]
}

// #MatchTransformers Tests

_testMatchTransformersHelper: {
	provider: #Provider & {
		apiVersion: "core.opmodel.dev/v0"
		kind:       "Provider"
		metadata: {
			name:        "test-provider"
			description: "Test"
			version:     "1.0.0"
			minVersion:  "1.0.0"
		}
		transformers: {
			"test.dev/transformers@v0#DeploymentTransformer":  _testProviderTransformer1
			"test.dev/transformers@v0#StatefulsetTransformer": _testProviderTransformer2
		}
	}

	module: #ModuleRelease & {
		metadata: {
			name:      "myapp"
			namespace: "production"
		}
		#module: {
			metadata: {
				apiVersion: "test.dev/modules@v0"
				name:       "myapp"
				version:    "1.0.0"
			}
			#config: {}
			values: {}
			#components: {
				web: #Component & {
					metadata: {
						name: "web"
						labels: {
							"core.opmodel.dev/workload-type": "stateless"
						}
					}
					#resources: {
						"test.dev/resources@v0#Container": _testTransformerResource
					}
					#traits: {}
					spec: {}
				}
				db: #Component & {
					metadata: {
						name: "db"
						labels: {
							"core.opmodel.dev/workload-type": "stateful"
						}
					}
					#resources: {
						"test.dev/resources@v0#Container": _testTransformerResource
					}
					#traits: {}
					spec: {}
				}
			}
		}
		values: {}
	}
}

_testMatchTransformersBasic: {
	let result = (#MatchTransformers & _testMatchTransformersHelper).out

	// Should have 2 entries (one per transformer)
	_deploymentMatch:  result["test.dev/transformers@v0#DeploymentTransformer"] != _|_
	_statefulsetMatch: result["test.dev/transformers@v0#StatefulsetTransformer"] != _|_

	// Deployment transformer should match 'web' component
	_webMatched: len(result["test.dev/transformers@v0#DeploymentTransformer"].components) == 1

	// StatefulSet transformer should match 'db' component
	_dbMatched: len(result["test.dev/transformers@v0#StatefulsetTransformer"].components) == 1
}

_testMatchTransformersNoMatches: {
	let result = (#MatchTransformers & {
		provider: _testMatchTransformersHelper.provider
		module: #ModuleRelease & {
			metadata: {
				name:      "myapp"
				namespace: "production"
			}
			#module: {
				metadata: {
					apiVersion: "test.dev/modules@v0"
					name:       "myapp"
					version:    "1.0.0"
				}
				#config: {}
				values: {}
				#components: {
					worker: #Component & {
						metadata: {
							name: "worker"
							labels: {
								"core.opmodel.dev/workload-type": "daemon"
							}
						}
						#resources: {}
						#traits: {}
						spec: {}
					}
				}
			}
			values: {}
		}
	}).out

	// Should have no matches
	_noMatches: len([for k, v in result {k}]) == 0
}

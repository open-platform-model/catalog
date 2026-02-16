@if(test)

package core

// =============================================================================
// Bundle & BundleRelease Definition Tests
// =============================================================================

// Helper module for bundle tests
_testBundleModule: #Module & {
	metadata: {
		apiVersion: "test.dev/modules@v0"
		name:       "bundle-test-module"
		version:    "1.0.0"
	}
	#components: {
		web: #Component & {
			metadata: {
				name: "web"
			}
			#resources: {
				"test.dev/resources@v0#Container": close(#Resource & {
					metadata: {
						apiVersion: "test.dev/resources@v0"
						name:       "container"
						labels: {
							"core.opmodel.dev/workload-type": "stateless"
						}
					}
					#spec: container: {
						name!:  #NameType
						image!: string
					}
				})
			}
			spec: container: {
				name:  "web"
				image: #config.image
			}
		}
	}
	#config: {
		image: string
	}
	values: {
		image: "nginx:latest"
	}
}

// Test: minimal valid bundle
_testBundleMinimal: #Bundle & {
	metadata: {
		apiVersion: "test.dev/bundles@v0"
		name:       "minimal-bundle"
	}
	#modules: {
		"test-module": _testBundleModule
	}
	#config: {
		image: string
	}
	values: {
		image: "nginx:latest"
	}
}

// Test: bundle with all optional fields
_testBundleFull: #Bundle & {
	metadata: {
		apiVersion:  "test.dev/bundles@v0"
		name:        "full-bundle"
		description: "A fully specified test bundle"
		labels: {
			"test.dev/tier": "platform"
		}
		annotations: {
			"test.dev/owner": "infra-team"
		}
	}
	#modules: {
		"test-module": _testBundleModule
	}
	#config: {
		image: string
	}
	values: {
		image: "nginx:latest"
	}
}

// Test: bundle release
_testBundleReleaseMinimal: #BundleRelease & {
	metadata: {
		name: "minimal-bundle-release"
	}
	#bundle: _testBundleMinimal
	values: {
		image: "nginx:1.25"
	}
}

// Helper module #2 for multi-module bundle
_testBundleModule2: #Module & {
	metadata: {
		apiVersion: "test.dev/modules@v0"
		name:       "bundle-test-module-2"
		version:    "1.0.0"
	}
	#components: {
		db: #Component & {
			metadata: {
				name: "db"
			}
			#resources: {
				"test.dev/resources@v0#Container": close(#Resource & {
					metadata: {
						apiVersion: "test.dev/resources@v0"
						name:       "container"
					}
					#spec: container: {
						name!:  #NameType
						image!: string
					}
				})
			}
			spec: container: {
				name:  "db"
				image: #config.dbImage
			}
		}
	}
	#config: {
		dbImage: string
	}
	values: {
		dbImage: "postgres:latest"
	}
}

// Test: bundle with multiple modules
_testBundleMultiModule: #Bundle & {
	metadata: {
		apiVersion: "test.dev/bundles@v0"
		name:       "multi-module-bundle"
	}
	#modules: {
		"web-module": _testBundleModule
		"db-module":  _testBundleModule2
	}
	#config: {
		image:   string
		dbImage: string
	}
	values: {
		image:   "nginx"
		dbImage: "postgres"
	}
}

// Test: bundle FQN computation
_testBundleFQN: #Bundle & {
	metadata: {
		apiVersion: "test.dev/bundles@v0"
		name:       "my-bundle"
		fqn:        "test.dev/bundles@v0#MyBundle"
	}
	#modules: {
		"test-module": _testBundleModule
	}
	#config: {
		image: string
	}
	values: {
		image: "nginx"
	}
}

// =============================================================================
// Negative Tests
// Negative tests moved to testdata/*.yaml files

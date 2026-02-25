@if(test)

package core

// =============================================================================
// ModuleRelease Definition Tests
// =============================================================================

// Helper module for release tests
_testReleaseModule: #Module & {
	metadata: {
		apiVersion: "test.dev/modules@v0"
		name:       "release-test-module"
		version:    "1.0.0"
	}
	#components: {
		web: #Component & {
			metadata: {
				name: "web"
			}
			#resources: {
				"test.dev/resources@v0#Container": #Resource & {
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
				}
			}
			spec: container: {
				name:  "web"
				image: #config.image
			}
		}
	}
	#config: {
		image:    string
		replicas: int & >=1
	}
	values: {
		image:    "nginx:latest"
		replicas: 1
	}
}

// Test: minimal valid module release
_testModuleReleaseMinimal: #ModuleRelease & {
	metadata: {
		name:      "minimal-release"
		namespace: "default"
	}
	#module: _testReleaseModule
	values: {
		image:    "nginx:1.25"
		replicas: 2
	}
}

// Test: module release with optional fields
_testModuleReleaseFull: #ModuleRelease & {
	metadata: {
		name:      "full-release"
		namespace: "production"
		labels: {
			"deploy.dev/env": "prod"
		}
		annotations: {
			"deploy.dev/team": "platform"
		}
	}
	#module: _testReleaseModule
	values: {
		image:    "nginx:1.25-alpine"
		replicas: 3
	}
}

// =============================================================================
// Negative tests moved to testdata/*.yaml files

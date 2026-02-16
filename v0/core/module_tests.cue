@if(test)

package core

// =============================================================================
// Module Definition Tests
// =============================================================================

// Helper resource for module tests
_testModResource: close(#Resource & {
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

// Helper component for module tests
_testModComponent: #Component & {
	metadata: {
		name: "web"
	}
	#resources: {
		(_testModResource.metadata.fqn): _testModResource
	}
	spec: {
		container: {
			name:  "web"
			image: string
		}
	}
}

// Test: minimal valid module
_testModuleMinimal: #Module & {
	metadata: {
		apiVersion: "test.dev/modules@v0"
		name:       "minimal-module"
		version:    "0.1.0"
	}
	#components: {
		web: _testModComponent & {
			spec: container: image: #config.image
		}
	}
	#config: {
		image: string
	}
	values: {
		image: "nginx:latest"
	}
}

// Test: module with all optional fields
_testModuleFull: #Module & {
	metadata: {
		apiVersion:       "test.dev/modules@v0"
		name:             "full-module"
		version:          "1.2.3"
		defaultNamespace: "production"
		description:      "A fully specified test module"
		labels: {
			"test.dev/tier": "backend"
		}
		annotations: {
			"test.dev/owner": "platform-team"
		}
	}
	#components: {
		web: _testModComponent & {
			spec: container: image: #config.image
		}
	}
	#config: {
		image: string
	}
	values: {
		image: "nginx:1.25"
	}
}

// Test: module FQN computation
_testModuleFQN: #Module & {
	metadata: {
		apiVersion: "test.dev/modules@v0"
		name:       "my-app"
		version:    "0.1.0"
		fqn:        "test.dev/modules@v0#MyApp"
	}
	#components: {
		web: _testModComponent & {
			spec: container: image: #config.image
		}
	}
	#config: {
		image: string
	}
	values: {
		image: "app:latest"
	}
}

// Test: module with SemVer pre-release version
_testModulePreRelease: #Module & {
	metadata: {
		apiVersion: "test.dev/modules@v0"
		name:       "prerelease-module"
		version:    "1.0.0-alpha.1"
	}
	#components: {
		web: _testModComponent & {
			spec: container: image: #config.image
		}
	}
	#config: {
		image: string
	}
	values: {
		image: "app:alpha"
	}
}

// Test: module with SemVer build metadata
_testModuleBuildMeta: #Module & {
	metadata: {
		apiVersion: "test.dev/modules@v0"
		name:       "build-meta-module"
		version:    "1.0.0+build.123"
	}
	#components: {
		web: _testModComponent & {
			spec: container: image: #config.image
		}
	}
	#config: {
		image: string
	}
	values: {
		image: "app:latest"
	}
}

// =============================================================================
// Negative tests moved to testdata/*.yaml files

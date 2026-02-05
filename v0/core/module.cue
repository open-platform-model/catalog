package core

// #Module: The portable application blueprint created by developers and/or platform teams
#Module: close({
	apiVersion: "opmodel.dev/core/v0"
	kind:       "Module"

	metadata: {
		apiVersion!: #NameType                          // Example: "example.com/modules@v0"
		name!:       #NameType                          // Example: "ExampleModule"
		fqn:         #FQNType & "\(apiVersion)#\(name)" // Example: "example.com/modules@v0#ExampleModule"

		version!: #VersionType // Semantic version of this module definition

		defaultNamespace?: string
		description?:      string
		labels?:           #LabelsAnnotationsType
		annotations?:      #LabelsAnnotationsType

		labels: #LabelsAnnotationsType & {
			// Standard labels for module identification
			"module.opmodel.dev/name":    "\(fqn)"
			"module.opmodel.dev/version": "\(version)"
		}
	}

	// Components defined in this module (developer-defined, required. May be added to by the platform-team)
	#components: [Id=string]: #Component & {
		metadata: {
			name: string | *Id
		}
	}

	// List of all components in this module
	// Useful for scopes that want to apply to all components
	// #allComponentsList: [for _, c in #components {c}]

	// Module-level scopes (developer-defined, optional. May be added to by the platform-team)
	#scopes?: [Id=string]: #Scope

	// Value schema - constraints only, NO defaults
	// Developers define the configuration contract and reference it in their components.
	// MUST be OpenAPIv3 compliant (no CUE templating - for/if statements)
	// config: _

	// Value schema - should contain sane default values
	// Developers define the configuration contract and reference it in their components.
	// MUST be OpenAPIv3 compliant (no CUE templating - for/if statements)
	#values: _
})

#ModuleMap: [string]: #Module

_testModule: #Module & {
	metadata: {
		apiVersion: "test.module.dev/modules@v0"
		name:       "TestModule"
		version:    "0.1.0"
	}

	#components: {
		"test-deployment": _testComponent
	}

	// config: {
	// 	replicaCount: int & >=1 & <=10
	// 	image:        string
	// }
	#values: {
		replicaCount: 3
		image:        "nginx:latest"
	}
}

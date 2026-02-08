package core

// #Module: The portable application blueprint created by developers and/or platform teams
#Module: close({
	apiVersion: "opmodel.dev/core/v0"
	kind:       "Module"

	metadata: {
		apiVersion!: #APIVersionType // Example: "example.com/modules@v0"
		name!:       #NameType       // Example: "example-module"
		_definitionName: (#KebabToPascal & {"in": name}).out
		fqn:      #FQNType & "\(apiVersion)#\(_definitionName)" // Example: "example.com/modules@v0#ExampleModule"
		version!: #VersionType                                  // Semantic version of this module definition

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
	// #allComponents: [for _, c in #components {c}]

	// Module-level scopes (developer-defined, optional. May be added to by the platform-team)
	#scopes?: [Id=string]: #Scope

	// Value schema - constraints only, NO defaults
	// Developers define the configuration contract and reference it in their components.
	// MUST be OpenAPIv3 compliant (no CUE templating - for/if statements)
	#config: _

	// Concrete values - should contain sane default values
	// Used as the basis for #ModuleRelease.values, but can be overridden by users/deployers when creating a release.
	values: #config
})

#ModuleMap: [string]: #Module

// Simplified module definition for testing purposes
_testModule: #Module & {
	metadata: {
		apiVersion: "test.module.dev/modules@v0"
		name:       "test-module"
		version:    "0.1.0"
	}

	#components: {
		"test-deployment": _testComponent & {
			spec: container: image: #config.image
			spec: scaling: count:   #config.replicaCount
		}
	}

	#config: {
		replicaCount: int & >=1
		image:        string
	}

	values: {
		replicaCount: 2
		image:        "nginx:12"
	}
}

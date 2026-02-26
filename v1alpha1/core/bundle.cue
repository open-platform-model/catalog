package core

// #Bundle: Defines a collection of modules. Bundles enable grouping
// related modules for easier distribution and management.
// Bundles can contain multiple modules, each representing a set of
// definitions (resources, traits, blueprints, policies).
#Bundle: {
	apiVersion: "opmodel.dev/core/v1alpha1"
	kind:       "Bundle"

	metadata: {
		modulePath!: #CUEModulePathType // Example: "opmodel.dev/bundles/core@v0"
		name!:          #NameType          // Example: "example-bundle"
		#definitionName: (#KebabToPascal & {"in": name}).out

		fqn: #FQNType & "\(modulePath)#\(#definitionName)" // Example: "opmodel.dev/bundles/core@v0#ExampleBundle"

		// Human-readable description of the bundle
		description?: string

		// Optional metadata labels for categorization and filtering
		labels?: #LabelsAnnotationsType

		// Optional metadata annotations for bundle behavior hints
		annotations?: #LabelsAnnotationsType
	}

	// Modules included in this bundle (full references)
	#modules!: #ModuleMap

	// Value schema - constraints only, NO defaults
	// MUST be OpenAPIv3 compliant (no CUE templating - for/if statements)
	#config!: _

	// debugValues: Example values for testing and debugging.
	// It is unified and validated in the runtime
	debugValues: _
}

#BundleDefinitionMap: [string]: #Bundle

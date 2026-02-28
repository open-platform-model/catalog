package core

import (
	cue_uuid "uuid"
)

// #Bundle: Defines a collection of modules.
// Bundles enable grouping related modules for easier distribution and management.
#Bundle: {
	apiVersion: "opmodel.dev/core/v1alpha1"
	kind:       "Bundle"

	metadata: {
		modulePath!: #ModulePathType                                     // Example: "opmodel.dev/bundles/core"
		name!:       #NameType                                           // Example: "example-bundle"
		version!:    #MajorVersionType                                   // Example: "0.1.0"
		fqn:         #ModuleFQNType & "\(modulePath)/\(name):\(version)" // Example: "opmodel.dev/bundles/core/example-bundle:v0.1.0"

		// Unique identifier for the bundle, computed as a UUID v5 (SHA1) of the FQN using the OPM namespace UUID.
		uuid: #UUIDType & cue_uuid.SHA1(OPMNamespace, fqn)
		#definitionName: (#KebabToPascal & {"in": name}).out

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

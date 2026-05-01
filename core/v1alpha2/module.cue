package v1alpha2

import (
	cue_uuid "uuid"
)

// #Module: The portable application blueprint created by developers and/or platform teams
#Module: {
	apiVersion: "opmodel.dev/core/v1alpha2"
	kind:       "Module"

	metadata: {
		modulePath!: #ModulePathType                                     // Example: "example.com/modules"
		name!:       #NameType                                           // Example: "example-module"
		version!:    #VersionType                                        // Example: "0.1.0"
		fqn:         #ModuleFQNType & "\(modulePath)/\(name):\(version)" // Example: "example.com/modules/example-module:0.1.0"

		// Unique identifier for the module, computed as a UUID v5 (SHA1) of the FQN using the OPM namespace UUID.
		uuid: #UUIDType & cue_uuid.SHA1(OPMNamespace, fqn)
		#definitionName: (#KebabToPascal & {"in": name}).out

		defaultNamespace?: string
		description?:      string
		labels?:           #LabelsAnnotationsType
		annotations?:      #LabelsAnnotationsType

		labels: {
			// Standard labels for module identification
			"module.opmodel.dev/name":    "\(name)"
			"module.opmodel.dev/version": "\(version)"
			"module.opmodel.dev/uuid":    "\(uuid)"
		}
	}

	// Components defined in this module (developer-defined, required. May be added to by the platform-team)
	#components: [Id=string]: #Component & {
		metadata: {
			name: string | *Id
			labels: "component.opmodel.dev/name": name
		}
	}

	// Value schema - constraints and defaults.
	// Developers define the configuration contract and reference it in their components.
	// MUST be OpenAPIv3 compliant (no CUE templating - for/if statements)
	#config: _

	// debugValues: Example values for testing and debugging.
	// It is unified and validated in the runtime
	debugValues: _
}

#ModuleMap: [string]: #Module

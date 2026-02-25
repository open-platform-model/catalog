package core

import (
	cue_uuid "uuid"
)

// #Module: The portable application blueprint created by developers and/or platform teams
#Module: {
	apiVersion: "opmodel.dev/core/v1alpha1"
	kind:       "Module"

	metadata: {
		cueModulePath!: #CUEModulePathType // Example: "example.com/modules@v1"
		name!:          #NameType          // Example: "example-module"
		#definitionName: (#KebabToPascal & {"in": name}).out

		version!: #VersionType // Semantic version of this module definition
		uuid:     #UUIDType & cue_uuid.SHA1(OPMNamespace, "\(cueModulePath)#\(#definitionName):\(version)")

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

	// List of all components in this module
	// Useful for policies that want to apply to all components
	// #allComponents: [for _, c in #components {c}]

	// Module-level policies (developer-defined, optional. May be added to by the platform-team)
	#policies?: [Id=string]: #Policy

	// Value schema - constraints and defaults.
	// Developers define the configuration contract and reference it in their components.
	// MUST be OpenAPIv3 compliant (no CUE templating - for/if statements)
	#config: _

	// debugValues: Example values for testing and debugging.
	// It is unified and validated in the runtime
	debugValues: _
}

#ModuleMap: [string]: #Module

_testModule: #Module & {
	metadata: {
		cueModulePath: "opmodel.dev/modules@v1"
		name:          "test-module"
		version:       "0.1.0"
		description:   "A test module for demonstration purposes"
		labels: {
			"module.opmodel.dev/category": "test"
		}
	}
	#components: {
		testComponent: _testComponent
	}

}

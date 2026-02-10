package core

import (
	"uuid"
)

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
		identity: #UUIDType & uuid.SHA1(OPMNamespace, "\(fqn):\(version)")

		defaultNamespace?: string
		description?:      string
		labels?:           #LabelsAnnotationsType
		annotations?:      #LabelsAnnotationsType

		labels: {
			// Standard labels for module identification
			"module.opmodel.dev/name":    "\(fqn)"
			"module.opmodel.dev/version": "\(version)"
			"module.opmodel.dev/uuid":    "\(identity)"
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

	// Value schema - constraints only, NO defaults
	// Developers define the configuration contract and reference it in their components.
	// MUST be OpenAPIv3 compliant (no CUE templating - for/if statements)
	#config: _

	// Concrete values - should contain sane default values from the author
	// These values are used when testing the module during development, and can be used as defaults when creating a ModuleRelease
	values: _
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

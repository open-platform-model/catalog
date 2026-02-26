package core

import (
	"strings"
)

// #Resource: Defines a resource of deployment within the system.
// Resources represent deployable components, services or resources that can be instantiated and managed independently.
#Resource: {
	apiVersion: "opmodel.dev/core/v1alpha1"
	kind:       "Resource"

	metadata: {
		modulePath!: #CUEModulePathType // Example: "resources.opmodel.dev/workload@v1"
		name!:          #NameType          // Example: "container"
		#definitionName: (#KebabToPascal & {"in": name}).out

		fqn: #FQNType & "\(modulePath)#\(#definitionName)" // Example: "resources.opmodel.dev/workload@v1#Container"

		// Human-readable description of the definition
		description?: string

		// Optional metadata labels for categorization and filtering
		// Labels are used by OPM for definition selection and matching
		// Example: {"core.opmodel.dev/workload-type": "stateless"}
		labels?: #LabelsAnnotationsType

		// Optional metadata annotations for definition behavior hints (not used for categorization)
		// Annotations provide additional metadata but are not used for selection
		annotations?: #LabelsAnnotationsType
	}

	// MUST be an OpenAPIv3 compatible schema
	// The field and schema exposed by this definition
	spec!: (strings.ToCamel(metadata.#definitionName)): _
}

#ResourceMap: [string]: _

_testContainerResource: #Resource & {
	metadata: {
		modulePath: "opmodel.dev/resources/workload@v1"
		name:          "container"
		description:   "A container definition for workloads"
	}

	// Default values for container resource
	#defaults: _testContainerDefaults

	// OpenAPIv3-compatible schema defining the structure of the container spec
	spec: container: _#testContainerSchema
}

_testContainer: #Component & {
	metadata: labels: {
		"core.opmodel.dev/workload-type"!: "stateless" | "stateful" | "daemon" | "task" | "scheduled-task"
		...
	}

	#resources: {(_testContainerResource.metadata.fqn): _testContainerResource}
}

_testContainerDefaults: _#testContainerSchema & {
}

_#testContainerSchema: {
	// Name of the container
	name!: string

	// Container image
	image!: _#testImageSchema

	// Command to run in the container
	command?: [...string]

	// Arguments to pass to the command
	args?: [...string]

	resources?: {
		requests?: {
			cpu?:    number | string & =~"^[0-9]+m$"
			memory?: number | string & =~"^[0-9]+[MG]i$"
		}
		limits?: {
			cpu?:    number | string & =~"^[0-9]+m$"
			memory?: number | string & =~"^[0-9]+[MG]i$"
		}
	}
}

_#testImageSchema: {
	repository!: string
	tag!:        string
	digest!:     string
	pullPolicy:  *"IfNotPresent" | "Always" | "Never"
}

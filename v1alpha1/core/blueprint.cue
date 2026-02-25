package core

import (
	"strings"
)

// #Blueprint: Defines a reusable blueprint
// that composes resources and traits into a higher-level abstraction.
// Blueprints enable standardized configurations for common use cases.
#Blueprint: {
	apiVersion: "opmodel.dev/core/v1alpha1"
	kind:       "Blueprint"

	metadata: {
		cueModulePath!: #CUEModulePathType // Example: "opmodel.dev/blueprints@v1"
		name!:          #NameType          // Example: "stateless-workload"
		#definitionName: (#KebabToPascal & {"in": name}).out

		fqn: #FQNType & "\(cueModulePath)#\(#definitionName)" // Example: "opmodel.dev/blueprints@v1#StatelessWorkload"

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

	// Resources that compose this blueprint (full references)
	composedResources!: [...#Resource]

	// Traits that compose this blueprint (full references)
	composedTraits?: [...#Trait]

	// MUST be an OpenAPIv3 compatible schema
	// The field and schema exposed by this definition
	spec!: (strings.ToCamel(metadata.#definitionName)): _
}

#BlueprintMap: [string]: #Blueprint

_testStatelessWorkloadBlueprint: #Blueprint & {
	metadata: {
		cueModulePath: "opmodel.dev/blueprints/workload@v1"
		name:          "stateless-workload"
		description:   "A stateless workload with no requirement for stable identity or storage"
	}

	composedResources: [_testContainerResource]

	composedTraits: [_testScalingTrait]

	spec: statelessWorkload: _#testStatelessWorkloadSchema
}

_testStatelessWorkload: #Component & {
	metadata: name: string | *"test-stateless-workload"
	metadata: labels: {
		"core.opmodel.dev/workload-type": "stateless"
	}

	#blueprints: (_testStatelessWorkloadBlueprint.metadata.fqn): _testStatelessWorkloadBlueprint

	_testContainer
	_testScaling

	// Override spec to propagate values from statelessWorkload
	spec: {
		statelessWorkload: _#testStatelessWorkloadSchema
		statelessWorkload: container: {
			name: string | *"test-container"
			image: {
				repository: string | *"nginx"
				tag:        string | *"latest"
				digest:     string | *""
			}
		}
		container: statelessWorkload.container
		if statelessWorkload.scaling != _|_ {
			scaling: statelessWorkload.scaling
		}
	}
}

_#testStatelessWorkloadSchema: {
	container: _#testContainerSchema
	scaling?: count: int
}

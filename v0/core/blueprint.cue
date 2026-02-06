package core

import (
	"strings"
)

// #Blueprint: Defines a reusable blueprint
// that composes resources and traits into a higher-level abstraction.
// Blueprints enable standardized configurations for common use cases.
#Blueprint: close({
	apiVersion: "opmodel.dev/core/v0"
	kind:       "Blueprint"

	metadata: {
		apiVersion!: #APIVersionType // Example: "opmodel.dev/blueprints@v0"
		name!:       #NameType       // Example: "stateless-workload"
		_definitionName: (#KebabToPascal & {"in": name}).out
		fqn: #FQNType & "\(apiVersion)#\(_definitionName)" // Example: "opmodel.dev/blueprints@v0#StatelessWorkload"

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
	// Use # to allow inconcrete fields
	// TODO: Add OpenAPIv3 schema validation
	#spec!: (strings.ToCamel(metadata._definitionName)): _
})

#BlueprintMap: [string]: #Blueprint

#BlueprintStringArray: [...string]

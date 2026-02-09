package core

import (
	"strings"
)

// #Trait: Defines additional behavior or characteristics that can be attached to components.
#Trait: close({
	apiVersion: "opmodel.dev/core/v0"
	kind:       "Trait"

	metadata: {
		apiVersion!: #APIVersionType // Example: "example.com/config-sources/traits/workload"
		name!:       #NameType       // Example: "scaling"
		_definitionName: (#KebabToPascal & {"in": name}).out
		fqn: #FQNType & "\(apiVersion)#\(_definitionName)" // Example: "opmodel.dev/traits/workload@v0#Scaling"

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
	// Use # to allow inconcrete fields
	// TODO: Add OpenAPIv3 schema validation
	#spec!: (strings.ToCamel(metadata._definitionName)): _

	// Resources that this trait can be applied to (full references)
	appliesTo!: [...#Resource]
})

#TraitMap: [string]: _

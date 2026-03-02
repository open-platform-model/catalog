package core

import (
	"strings"
)

// #Trait: Defines additional behavior or characteristics that can be attached to components.
#Trait: {
	apiVersion: "opmodel.dev/core/v1alpha1"
	kind:       "Trait"

	metadata: {
		modulePath!: #ModulePathType   // Example: "opmodel.dev/traits/workload"
		version!:    #MajorVersionType // Example: "v1"
		name!:       #NameType         // Example: "scaling"
		#definitionName: (#KebabToPascal & {"in": name}).out

		fqn: #FQNType & "\(modulePath)/\(name)@\(version)" // Example: "opmodel.dev/traits/workload/scaling@v1"

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

	// Resources that this trait can be applied to (full references)
	appliesTo!: [...#Resource]
}

#TraitMap: [string]: _

_testScalingTrait: #Trait & {
	metadata: {
		modulePath:  "opmodel.dev/traits/workload"
		version:     "v1"
		name:        "scaling"
		description: "A trait for scaling workloads"
	}

	appliesTo: [_testContainerResource]

	#defaults: _testScalingDefaults

	spec: scaling: _#testScalingSchema
}

_testScaling: #Component & {
	#traits: {(_testScalingTrait.metadata.fqn): _testScalingTrait}
}

_#testScalingSchema: {
	count: int & >=1 & <=1000
}

_testScalingDefaults: _#testScalingSchema & {count: 1}

package primitives

import (
	"strings"
	t "opmodel.dev/core/v1alpha1/types@v1"
)

// #Directive: Describes operational behavior that the platform
// should execute on behalf of the module author.
// Directives carry no enforcement semantics — they are not
// governance rules. They live inside #Policy alongside #PolicyRule.
#Directive: {
	apiVersion: "opmodel.dev/core/v1alpha1"
	kind:       "Directive"

	metadata: {
		modulePath!: t.#ModulePathType   // Example: "opmodel.dev/opm/v1alpha1/directives/data"
		version!:    t.#MajorVersionType // Example: "v1"
		name!:       t.#NameType         // Example: "backup"
		#definitionName: (t.#KebabToPascal & {"in": name}).out

		fqn: t.#FQNType & "\(modulePath)/\(name)@\(version)" // Example: "opmodel.dev/opm/v1alpha1/directives/data/backup@v1"

		description?: string

		labels?:      t.#LabelsAnnotationsType
		annotations?: t.#LabelsAnnotationsType
	}

	// MUST be an OpenAPIv3 compatible schema
	// The field and schema exposed by this definition
	#spec!: (strings.ToCamel(metadata.name)): _
}

#DirectiveMap: [string]: _

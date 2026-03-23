package extension

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/opm/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// CRDs Resource Definition
/////////////////////////////////////////////////////////////////

#CRDsResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/opm/resources/extension"
		version:     "v1"
		name:        "crds"
		description: "One or more CustomResourceDefinitions to deploy to the cluster"
		labels: {
			"resource.opmodel.dev/category": "extension"
		}
	}

	// Default values for CRDs resource
	#defaults: #CRDsDefaults

	// Map of CRDs keyed by a stable identifier (typically "<plural>.<group>")
	spec: close({crds: [name=string]: schemas.#CRDSchema})
}

#CRDs: component.#Component & {

	#resources: {(#CRDsResource.metadata.fqn): #CRDsResource}
}

#CRDsDefaults: {
	scope: *"Namespaced" | "Cluster"
}

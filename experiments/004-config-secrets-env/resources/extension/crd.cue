package extension

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// CRDs Resource Definition
/////////////////////////////////////////////////////////////////

#CRDsResource: core.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/resources/extension"
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

#CRDs: core.#Component & {
	metadata: annotations: {
		"transformer.opmodel.dev/list-output": true
	}

	#resources: {(#CRDsResource.metadata.fqn): #CRDsResource}
}

#CRDsDefaults: {
	scope: *"Namespaced" | "Cluster"
}

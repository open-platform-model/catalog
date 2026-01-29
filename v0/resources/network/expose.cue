package network

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
)

/////////////////////////////////////////////////////////////////
//// Expose Resource Definition
/////////////////////////////////////////////////////////////////

#ExposeResource: close(core.#Resource & {
	metadata: {
		apiVersion:  "opmodel.dev/resources/network@v0"
		name:        "Expose"
		description: "A resource to expose a network service"
		labels: {
			"core.opmodel.dev/category": "network"
		}
	}

	// Default values for expose resource
	#defaults: #ExposeDefaults

	#spec: expose: schemas.#ExposeSchema
})

#Expose: close(core.#Component & {
	#resources: {(#ExposeResource.metadata.fqn): #ExposeResource}
})

#ExposeDefaults: close(schemas.#ExposeSchema & {
	// Default service type
	type: *"ClusterIP" | "NodePort" | "LoadBalancer"
})

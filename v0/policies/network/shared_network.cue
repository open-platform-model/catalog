package network

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
)

/////////////////////////////////////////////////////////////////
//// SharedNetwork Policy Definition
/////////////////////////////////////////////////////////////////

#SharedNetworkPolicy: close(core.#PolicyRule & {
	metadata: {
		apiVersion:  "opmodel.dev/policies/connectivity@v0"
		name:        "shared-network"
		description: "Allows all network traffic between components in the same policy based on their exposed ports"
	}

	enforcement: {
		mode:        "deployment"
		onViolation: "block"
	}

	#spec: sharedNetwork: schemas.#SharedNetworkSchema
})

#SharedNetwork: close(core.#Policy & {
	#rules: {(#SharedNetworkPolicy.metadata.fqn): #SharedNetworkPolicy}
})

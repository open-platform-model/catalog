package network

import (
	core "opm.dev/core@v0"
	schemas "opm.dev/schemas@v0"
)

/////////////////////////////////////////////////////////////////
//// SharedNetwork Policy Definition
/////////////////////////////////////////////////////////////////

#SharedNetworkPolicy: close(core.#Policy & {
	metadata: {
		apiVersion:  "opm.dev/policies/connectivity@v0"
		name:        "SharedNetwork"
		description: "Allows all network traffic between components in the same scope based on their exposed ports"
		target:      "scope"
	}
	enforcement: {
		mode:        "deployment"
		onViolation: "block"
	}

	#spec: SharedNetwork: schemas.#SharedNetworkSchema
})

#SharedNetwork: close(core.#Scope & {
	#policies: {(#SharedNetworkPolicy.metadata.fqn): #SharedNetworkPolicy}
})

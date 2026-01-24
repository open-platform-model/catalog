package network

import (
	core "opm.dev/core@v0"
	schemas "opm.dev/schemas@v0"
)

/////////////////////////////////////////////////////////////////
//// SharedNetwork Policy Definition
/////////////////////////////////////////////////////////////////

#SharedNetworkPolicy: close(core.#PolicyDefinition & {
	metadata: {
		apiVersion:  "opm.dev/policies/connectivity@v0"
		name:        "SharedNetwork"
		description: "Allows all network traffic between components in the same scope based on their exposed ports"
		target:      core.#PolicyTarget.scope // Scope-only
	}
	enforcement: {
		mode:        "deployment"
		onViolation: "block"
	}

	// Default values for shared network policy
	#defaults: #SharedNetworkDefaults

	#spec: sharedNetwork: schemas.#SharedNetworkSchema
})

#SharedNetwork: close(core.#ScopeDefinition & {
	#policies: {(#SharedNetworkPolicy.metadata.fqn): #SharedNetworkPolicy}
})

#SharedNetworkDefaults: close(schemas.#SharedNetworkSchema & {
	networkConfig: {
		dnsPolicy: "ClusterFirst"
	}
})

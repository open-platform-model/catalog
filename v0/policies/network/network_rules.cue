package network

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
)

/////////////////////////////////////////////////////////////////
//// NetworkRules Policy Definition
/////////////////////////////////////////////////////////////////

#NetworkRulesPolicy: close(core.#Policy & {
	metadata: {
		apiVersion:  "opmodel.dev/policies/connectivity@v0"
		name:        "NetworkRules"
		description: "Defines network traffic rules"
		target:      "scope"
	}
	enforcement: {
		mode:        "deployment"
		onViolation: "block"
	}

	#spec: NetworkRules: [ruleName=string]: schemas.#NetworkRuleSchema
})

#NetworkRules: close(core.#Scope & {
	#policies: {(#NetworkRulesPolicy.metadata.fqn): #NetworkRulesPolicy}
})

package network

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
)

/////////////////////////////////////////////////////////////////
//// NetworkRules Policy Definition
/////////////////////////////////////////////////////////////////

#NetworkRulesPolicy: core.#PolicyRule & {
	metadata: {
		apiVersion:  "opmodel.dev/policies/connectivity@v0"
		name:        "network-rules"
		description: "Defines network traffic rules"
	}

	enforcement: {
		mode:        "deployment"
		onViolation: "block"
	}

	#spec: networkRules: [ruleName=string]: schemas.#NetworkRuleSchema
}

#NetworkRules: core.#Policy & {
	#rules: {(#NetworkRulesPolicy.metadata.fqn): #NetworkRulesPolicy}
}

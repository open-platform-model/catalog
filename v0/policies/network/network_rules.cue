package network

import (
	core "opm.dev/core@v0"
	schemas "opm.dev/schemas@v0"
)

/////////////////////////////////////////////////////////////////
//// NetworkRules Policy Definition
/////////////////////////////////////////////////////////////////

#NetworkRulesPolicy: close(core.#PolicyDefinition & {
	metadata: {
		apiVersion:  "opm.dev/policies/connectivity@v0"
		name:        "NetworkRules"
		description: "Defines network traffic rules"
		target:      core.#PolicyTarget.scope // Scope-only
	}
	enforcement: {
		mode:        "deployment"
		onViolation: "block"
	}

	// Default values for network rules policy
	#defaults: #NetworkRulesDefaults

	#spec: networkRules: [ruleName=string]: schemas.#NetworkRuleSchema
})

#NetworkRules: close(core.#ScopeDefinition & {
	#policies: {(#NetworkRulesPolicy.metadata.fqn): #NetworkRulesPolicy}
})

#NetworkRulesDefaults: close(schemas.#NetworkRuleSchema & {})

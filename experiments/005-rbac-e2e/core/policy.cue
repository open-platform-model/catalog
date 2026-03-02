package core

// #Policy: Groups PolicyRules and targets them to a set of
// components via label matching or explicit references.
// Policies enable cross-cutting governance without coupling
// rules to individual components.
#Policy: {
	apiVersion: "opmodel.dev/core/v0"
	kind:       "Policy"

	metadata: {
		name!: #NameType

		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	// PolicyRules grouped by this policy
	#rules: [RuleFQN=string]: #PolicyRule & {
		metadata: {
			name: string | *RuleFQN
		}
	}

	// Which components this policy applies to
	// At least one of matchLabels or components must be specified
	appliesTo: {
		// Label-based matching — select components whose labels are a superset
		matchLabels?: #LabelsAnnotationsType

		// Explicit component references
		components?: [...#Component]
	}

	_allFields: {
		if #rules != _|_ {
			for _, rule in #rules {
				if rule.#spec != _|_ {
					for k, v in rule.#spec {
						(k): v
					}
				}
			}
		}
	}

	// Fields exposed by this policy
	// Automatically turned into a spec
	// Must be made concrete by the user
	spec: close(_allFields)
}

#PolicyMap: [string]: #Policy

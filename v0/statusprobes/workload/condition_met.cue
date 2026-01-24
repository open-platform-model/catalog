package workload

import (
	core "opm.dev/core@v0"
)

// #ConditionMet: Generic check for a specific condition status
#ConditionMet: core.#StatusProbe & {
	metadata: {
		apiVersion: "opm.dev/probes/workload@v0"
		name:       "ConditionMet"
		description: "Checks if a specific condition is met"
	}

	#params: {
		name:   string
		type:   string | *"Ready"
		status: string | *"True"
	}

	result: {
		let res = context.outputs[#params.name]
		let conditions = [for c in res.status.conditions if c.type == #params.type {c}]
		
		healthy: len(conditions) > 0 && conditions[0].status == #params.status
		
		message: {
			if healthy {
				"Resource '\(#params.name)' condition '\(#params.type)' is '\(#params.status)'"
			}
			if !healthy {
				"Resource '\(#params.name)' condition '\(#params.type)' is NOT '\(#params.status)'"
			}
		}
	}
}

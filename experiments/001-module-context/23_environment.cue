package module_context

// #Environment: deployment-target binding. Layer 2 of the context hierarchy.
// #ModuleRelease.#env points at an #Environment value.
#Environment: {
	apiVersion: "opmodel.dev/experiments/module_context/v0"
	kind:       "Environment"

	metadata: {
		name!:        #NameType
		description?: string
	}

	#platform!: #Platform

	#ctx: #EnvironmentContext
}

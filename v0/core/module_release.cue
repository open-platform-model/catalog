package core

// #ModuleRelease: The concrete deployment instance
// Contains: Reference to Module, concrete values (closed), target namespace
// Users/deployment systems create this to deploy a specific version
#ModuleRelease: close({
	apiVersion: "opm.dev/core/v0"
	kind:       "ModuleRelease"

	metadata: {
		name!:        string
		namespace!:   string // Required for releases (target environment)
		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	// Reference to the Module to deploy
	#module!: #CompiledModule | #Module

	_module: #module & {#values: values}
	components: _module.#components
	if _module.#scopes != _|_ {
		scopes: _module.#scopes
	}
	if _module.#policies != _|_ {
		scopes: _module.#policies
	}

	// Concrete values (everything closed/concrete)
	// Must satisfy the value schema from #module.#spec
	values!: close(#module.#spec)

	if #module.#status != _|_ {status: #module.#status}
	status?: close({
		// Deployment lifecycle phase
		phase: "pending" | "deployed" | "failed" | "unknown" | *"pending"

		// Human-readable status message
		message?: string

		// Detailed status conditions (Kubernetes-style)
		conditions?: [...{
			type:                string // e.g., "Available", "Progressing", "Degraded"
			status:              "True" | "False" | "Unknown"
			reason?:             string
			message?:            string
			lastTransitionTime?: string // ISO 8601 timestamp
		}]

		// Deployment timestamp
		deployedAt?: string // ISO 8601 timestamp

		// Resources created by this release
		resources?: {
			count?: int
			kinds?: [...string]
		}
	})
})

#ModuleReleaseMap: [string]: #ModuleRelease

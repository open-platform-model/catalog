package core

// #Module: The portable application blueprint created by developers and/or platform teams
// Developers: Create initial ModuleDefinitions with application intent
// Platform teams: Can inherit and extend upstream ModuleDefinitions via CUE unification
// Contains: Components, value schema (constraints only), optional module scopes
// Does NOT contain: Concrete values, flattened state
#Module: close({
	apiVersion: "opm.dev/core/v0"
	kind:       "Module"

	metadata: {
		apiVersion!: #NameType                          // Example: "example.com/modules@v0"
		name!:       #NameType                          // Example: "ExampleModule"
		fqn:         #FQNType & "\(apiVersion)#\(name)" // Example: "example.com/modules@v0#ExampleModule"

		version!: #VersionType // Semantic version of this module definition

		defaultNamespace?: string
		description?:      string
		labels?:           #LabelsAnnotationsType
		annotations?:      #LabelsAnnotationsType
	}

	// Components defined in this module (developer-defined, required. May be added to by the platform-team)
	#components: [Id=string]: #Component & {
		metadata: {
			name:      string | *Id
			namespace: string | *metadata.defaultNamespace
		}
	}

	// List of all components in this module
	// Useful for scopes that want to apply to all components
	#allComponentsList: [for _, c in #components {c}]

	// Module-level scopes (developer-defined, optional. May be added to by the platform-team)
	#scopes?: [Id=string]: #Scope

	// Value schema - constraints only, NO defaults
	// Developers define the configuration contract
	// Platform teams can add defaults and refine constraints via CUE merging
	// MUST be OpenAPIv3 compliant (no CUE templating - for/if statements)
	#spec: _

	// Concrete values - should contain sane default values
	// Developers define these values but it can be overriden by the platform operator.
	// The end-user's concrete values override this except if a platform operator has already defined them.
	values: _

	// Status: Computed during CUE evaluation
	// Has full access to: metadata, #components, #scopes, #spec, values
	// Use for: configuration summaries, derived health checks, validation status
	// See: opm/specs/001-opm-cue-spec/subsystems/module-status.md
	#status?: #ModuleStatus
})

#ModuleMap: [string]: #Module

// #ModuleStatus: Status computed during CUE evaluation
// Developers define what constitutes "healthy" and what details to expose
// All expressions are pure CUE with full access to module structure
#ModuleStatus: {
	// Structured diagnostic information (key-value pairs)
	// Only primitive types allowed for portability
	details?: [string]: bool | int | string
	// Overall health indicator
	// Must evaluate to a concrete boolean
	valid?: bool
	// Human-readable status message
	message?: string
	// Module phase derived from health (convenience field)
	phase?: "healthy" | "degraded" | "unknown"
	// Composable Runtime Probes
	// A map of probes that will be evaluated at runtime by the controller.
	// The controller unifies live state into these probes to determine runtime health.
	#probes?: #StatusProbeMap
}

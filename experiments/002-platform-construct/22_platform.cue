package platform_construct

// #ModuleRegistration — single entry in #Platform.#registry.
// Pure projection of "this Module's primitives are visible on this platform".
// Carries no install metadata (014 D11). enabled: false hides every projection
// (014 D14). presentation is flat (014 D14, post-D11 cleanup).
#ModuleRegistration: {
	#module!: #Module

	enabled: bool | *true

	presentation?: {
		description?: string
		category?:    string
		tags?: [...string]
		examples?: [Name=string]: {
			description?: string
			values:       _
		}
	}

	metadata?: {
		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}
}

// #PlatformBase — every projection except the multi-fulfiller hard-fail
// constraint. Used by tests that need to inspect #matchers._invalid as a
// diagnostic surface (the strict #Platform definition would short-circuit
// to _|_ before a test could read _invalid).
//
// Real schema lifts to #Platform with the constraint enabled (see below).
#PlatformBase: {
	apiVersion: "opmodel.dev/core/v1alpha2"
	kind:       "Platform"

	metadata: {
		name!:        #NameType
		description?: string
		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	// #Platform.type — kept as authored field. Future enhancement may enforce
	// type-vs-transformer compatibility; today informational (014 OQ2).
	type!: string

	// Platform-level context — stubbed open in this experiment. Real schema
	// types this as #PlatformContext from 016.
	#ctx?: _

	// #registry — kebab-case Id key (014 D16). Static + runtime writes
	// unify by Id; concrete-value disagreement = _|_ surfaced by reconciler
	// (014 D15).
	#registry: [Id=#NameType]: #ModuleRegistration

	// ---- Computed views over #registry ----
	// Each gates on `reg.enabled` (014 D14 — disabled entries hide
	// everything, types and transformers alike).

	#knownResources: {
		[FQN=string]: #Resource
		for _, reg in #registry
		if reg.enabled
		if reg.#module.#defines != _|_
		if reg.#module.#defines.resources != _|_
		for fqn, v in reg.#module.#defines.resources {
			(fqn): v
		}
	}

	#knownTraits: {
		[FQN=string]: #Trait
		for _, reg in #registry
		if reg.enabled
		if reg.#module.#defines != _|_
		if reg.#module.#defines.traits != _|_
		for fqn, v in reg.#module.#defines.traits {
			(fqn): v
		}
	}

	#knownClaims: {
		[FQN=string]: #Claim
		for _, reg in #registry
		if reg.enabled
		if reg.#module.#defines != _|_
		if reg.#module.#defines.claims != _|_
		for fqn, v in reg.#module.#defines.claims {
			(fqn): v
		}
	}

	#composedTransformers: #TransformerMap & {
		for _, reg in #registry
		if reg.enabled
		if reg.#module.#defines != _|_
		if reg.#module.#defines.transformers != _|_
		for fqn, v in reg.#module.#defines.transformers {
			(fqn): v
		}
	}

	// ---- Match index (014 D12) ----
	//
	// Pre-compute candidate maps as `let` bindings so the _invalid
	// projection can iterate them directly. Iterating the published
	// fields (resources / traits / claims) fails with "incomplete type
	// list" because the field type is `[FQN]: [...#ComponentTransformer]`
	// — an open value-list — which CUE refuses to range over.
	#matchers: {
		let _resourceFqns = {
			for _, t in #composedTransformers
			if t.kind == "ComponentTransformer"
			if t.requiredResources != _|_
			for fqn, _ in t.requiredResources {
				(fqn): _
			}
		}
		let _traitFqns = {
			for _, t in #composedTransformers
			if t.kind == "ComponentTransformer"
			if t.requiredTraits != _|_
			for fqn, _ in t.requiredTraits {
				(fqn): _
			}
		}
		let _claimFqns = {
			for _, t in #composedTransformers
			if t.requiredClaims != _|_
			for fqn, _ in t.requiredClaims {
				(fqn): _
			}
		}

		let _resourceCandidates = {
			for fqn, _ in _resourceFqns {
				(fqn): [
					for _, t in #composedTransformers
					if t.kind == "ComponentTransformer"
					if t.requiredResources != _|_
					if t.requiredResources[fqn] != _|_ {t},
				]
			}
		}
		let _traitCandidates = {
			for fqn, _ in _traitFqns {
				(fqn): [
					for _, t in #composedTransformers
					if t.kind == "ComponentTransformer"
					if t.requiredTraits != _|_
					if t.requiredTraits[fqn] != _|_ {t},
				]
			}
		}
		let _claimCandidates = {
			for fqn, _ in _claimFqns {
				(fqn): [
					for _, t in #composedTransformers
					if t.requiredClaims != _|_
					if t.requiredClaims[fqn] != _|_ {t},
				]
			}
		}

		resources: {[FQN=string]: [...#ComponentTransformer]} & _resourceCandidates
		traits: {[FQN=string]: [...#ComponentTransformer]} & _traitCandidates
		claims: {[FQN=string]: [...(#ComponentTransformer | #ModuleTransformer)]} & _claimCandidates

		// Diagnostic surface — iterates the let-binding candidate maps
		// (concrete) rather than the typed published fields.
		_invalid: {
			resources: [
				for fqn, ts in _resourceCandidates
				if len(ts) > 1 {fqn},
			]
			traits: [
				for fqn, ts in _traitCandidates
				if len(ts) > 1 {fqn},
			]
			claims: [
				for fqn, ts in _claimCandidates
				if len(ts) > 1 {fqn},
			]
		}
	}
}

// #Platform — strict form. Adds the multi-fulfiller hard-fail constraint
// (014 D13). Use this for production schemas; use #PlatformBase only when a
// test needs to inspect _invalid before the constraint short-circuits.
#Platform: #PlatformBase & {
	#matchers: _noMultiFulfiller: 0 & (len(#matchers._invalid.resources) +
		len(#matchers._invalid.traits) +
		len(#matchers._invalid.claims))
}

// #PlatformMatch — per-deploy walker. Resolves a consumer Module's FQN demand
// against #Platform.#matchers and surfaces matched / unmatched / ambiguous.
#PlatformMatch: {
	platform!: #PlatformBase
	module!:   #Module

	// ---- Demand: FQNs the consumer Module reads ----
	//
	// Aliased the consumer module to _consumer because `_demand.claims`
	// has a `module:` sub-field — naming-by-shadow would resolve `module`
	// inside the sub-comprehensions to the sibling FQN map, not the
	// input. Caught by experiments/002 t06.
	_demand: {
		let _consumer = module

		resources: [FQN=string]: _
		resources: {
			if _consumer.#components != _|_
			for _, c in _consumer.#components
			if c.#resources != _|_
			for fqn, _ in c.#resources {
				(fqn): _
			}
		}

		traits: [FQN=string]: _
		traits: {
			if _consumer.#components != _|_
			for _, c in _consumer.#components
			if c.#traits != _|_
			for fqn, _ in c.#traits {
				(fqn): _
			}
		}

		claims: {
			module: [FQN=string]: _
			module: {
				if _consumer.#claims != _|_
				for _, claim in _consumer.#claims {
					(claim.metadata.fqn): _
				}
			}
			component: [FQN=string]: _
			component: {
				if _consumer.#components != _|_
				for _, c in _consumer.#components
				if c.#claims != _|_
				for _, claim in c.#claims {
					(claim.metadata.fqn): _
				}
			}
		}
	}

	// ---- Lookup: candidate transformers per demanded FQN ----
	matched: {
		resources: [FQN=string]: [...#ComponentTransformer]
		resources: {
			for fqn, _ in _demand.resources
			if platform.#matchers.resources[fqn] != _|_ {
				(fqn): platform.#matchers.resources[fqn]
			}
		}

		traits: [FQN=string]: [...#ComponentTransformer]
		traits: {
			for fqn, _ in _demand.traits
			if platform.#matchers.traits[fqn] != _|_ {
				(fqn): platform.#matchers.traits[fqn]
			}
		}

		claims: [FQN=string]: [...(#ComponentTransformer | #ModuleTransformer)]
		claims: {
			for fqn, _ in _demand.claims.module
			if platform.#matchers.claims[fqn] != _|_ {
				(fqn): platform.#matchers.claims[fqn]
			}
			for fqn, _ in _demand.claims.component
			if platform.#matchers.claims[fqn] != _|_ {
				(fqn): platform.#matchers.claims[fqn]
			}
		}
	}

	// ---- Diagnostics ----
	// Claims dedup module + component demand via a hidden union map.
	// (Original `_demand.claims.module & _demand.claims.component` was buggy —
	// CUE struct `&` is unification, intersect-of-keys, not union.)
	//
	// Pre-build matched-FQN sets and check membership via `== _|_` against
	// a struct we built ourselves. `cue vet -c` errors on undefined-field
	// access against typed siblings (matched.{resources,traits,claims}),
	// so we route through a concrete key-set first.
	unmatched: {
		let _claimDemand = {
			for fqn, _ in _demand.claims.module {(fqn): _}
			for fqn, _ in _demand.claims.component {(fqn): _}
		}
		let _matchedResourceSet = {
			for fqn, _ in matched.resources {(fqn): _}
		}
		let _matchedTraitSet = {
			for fqn, _ in matched.traits {(fqn): _}
		}
		let _matchedClaimSet = {
			for fqn, _ in matched.claims {(fqn): _}
		}
		resources: [
			for fqn, _ in _demand.resources
			if _matchedResourceSet[fqn] == _|_ {fqn},
		]
		traits: [
			for fqn, _ in _demand.traits
			if _matchedTraitSet[fqn] == _|_ {fqn},
		]
		claims: [
			for fqn, _ in _claimDemand
			if _matchedClaimSet[fqn] == _|_ {fqn},
		]
	}

	// ambiguous — should always be empty on #Platform (D13). Populated only
	// against #PlatformBase (diagnostic).
	ambiguous: {
		resources: {
			for fqn, ts in matched.resources
			if len(ts) > 1 {
				(fqn): ts
			}
		}
		traits: {
			for fqn, ts in matched.traits
			if len(ts) > 1 {
				(fqn): ts
			}
		}
		claims: {
			for fqn, ts in matched.claims
			if len(ts) > 1 {
				(fqn): ts
			}
		}
	}
}

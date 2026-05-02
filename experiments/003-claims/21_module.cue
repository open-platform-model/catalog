package claims

// Stub #Component — minimal surface for transformer match-keys (#resources,
// #traits, #claims) AND for transformer bodies that read concrete `spec`
// values + injected `#claims.<id>.#status` writes.
#Component: {
	metadata: {
		name!:         #NameType
		resourceName?: #NameType
		labels?:       #LabelsAnnotationsType
		annotations?:  #LabelsAnnotationsType
	}
	#resources?: [FQN=string]: _
	#traits?: [FQN=string]:    _

	// Component-level claims keyed by author-chosen id. Identity travels via
	// embedded claim.metadata.fqn. Two components with the same claim id are
	// independent fulfilment instances (CL-D17).
	#claims?: [string]: #Claim
	spec?: _
}

// Eight-slot #Module shape (015 MS-D2).
//
// Slot list: metadata (nucleus), #config (nucleus), debugValues (nucleus),
// #components (nucleus), #lifecycles (inward), #workflows (inward), #claims
// (outward instance), #defines (outward publication).
//
// #lifecycles, #workflows, #config, debugValues left as opaque stubs — the
// pipeline experiment doesn't exercise their bodies.
//
// CL-D18 — module-level Claim FQN uniqueness — enforced via the hidden
// _noDuplicateModuleClaimFqn field. Two #claims entries sharing a FQN make
// the count length > 1, then `1 & 2` ⇒ _|_ at evaluation time.
#Module: {
	apiVersion: "opmodel.dev/core/v1alpha2"
	kind:       "Module"
	metadata: {
		modulePath!:  #ModulePathType
		name!:        #NameType
		version!:     #VersionType
		fqn!:         #ModuleFQNType
		uuid!:        #UUIDType
		description?: string
		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	// Nucleus opaque slots — present on the def to validate MS-D2 acceptance.
	#config?:     _
	debugValues?: _

	#components?: [Id=string]: #Component & {
		metadata: name: string | *Id
	}

	// Inward stubs (015 04-module-shape.md "left as stubs").
	#lifecycles?: [Id=string]: _
	#workflows?: [Id=string]:  _

	// Outward instance — module-level Claims (e.g. DNS, identity, mesh tenant).
	#claims?: [string]: #Claim

	// Outward publication — DEF-D2 FQN-binding on each sub-map.
	#defines?: {
		resources?: [FQN=string]: #Resource & {metadata: fqn: FQN}
		traits?: [FQN=string]: #Trait & {metadata: fqn: FQN}
		claims?: [FQN=string]: #Claim & {metadata: fqn: FQN}
		transformers?: [FQN=string]: (#ComponentTransformer | #ModuleTransformer) & {metadata: fqn: FQN}
	}

	// CL-D18 — module-level Claim FQN uniqueness. Hidden field; tests force
	// evaluation by referencing it. Each FQN must appear exactly once across
	// all #claims ids.
	let _moduleClaimFqns = [
		if #claims != _|_
		for _, c in #claims {c.metadata.fqn},
	]
	_noDuplicateModuleClaimFqn: {
		for fqn in _moduleClaimFqns {
			(fqn): 1 & len([for x in _moduleClaimFqns if x == fqn {true}])
		}
	}
}

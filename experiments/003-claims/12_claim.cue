package claims

// #Claim primitive (015 CL-D4 + CL-D15).
//
// metadata.fqn is BOUND to "modulePath/name@version" via unification — concrete
// claim definitions don't have to repeat the FQN, and a typo on any of the
// three components produces _|_ at definition time.
//
// #spec stays open in the experiment (production schema does
// `((#KebabToCamel & {"in": metadata.name}).out): _` — the kebab-to-camel
// derivation doesn't affect pipeline mechanics, deferred per Risk R5).
//
// #status is the writeback target. Concrete claim defs may pin a #status
// schema (quartet pattern, CL-D6); when the matching transformer's
// #statusWrites resolves to a value that doesn't satisfy the pinned schema,
// CUE unification fails and surfaces the contract violation.
#Claim: {
	apiVersion!: string
	kind:        "Claim"
	metadata: {
		modulePath!:  #ModulePathType
		name!:        #NameType
		version!:     #MajorVersionType
		fqn:          #FQNType & "\(modulePath)/\(name)@\(version)"
		description?: string
	}
	#spec?:   _
	#status?: _
}

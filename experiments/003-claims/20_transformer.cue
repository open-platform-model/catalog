package claims

// Two-primitive transformer split (014 D17 + 015 TR-D5).
//
// #ComponentTransformer fires once per matching component (014/05).
// #ModuleTransformer fires once per matching module (015/07).
//
// Both gain #statusWrites?: [claimId=string]: _ on the #transform body
// (CL-D15, CL-D16). Keys are the consumer's #claims map keys, resolved by
// FQN-equality between the transformer's requiredClaims and the matched
// scope's #claims.<id>.metadata.fqn.

#ComponentTransformer: {
	apiVersion: "opmodel.dev/core/v1alpha2"
	kind:       "ComponentTransformer"
	metadata: {
		modulePath!:  #ModulePathType
		version!:     #MajorVersionType
		name!:        #NameType
		fqn!:         #FQNType
		description?: string
	}
	requiredLabels?: #LabelsAnnotationsType
	optionalLabels?: #LabelsAnnotationsType
	requiredResources?: [FQN=string]: _
	optionalResources?: [FQN=string]: _
	requiredTraits?: [FQN=string]:    _
	optionalTraits?: [FQN=string]:    _
	requiredClaims?: [FQN=string]:    _
	optionalClaims?: [FQN=string]:    _

	readsContext?: [...string]
	producesKinds?: [...string]

	#transform?: {
		#moduleRelease: _
		#component:     _
		#context:       #TransformerContext

		// Per-claim status the dispatcher writes back into the matched
		// #Claim instance's #status. Map key is the consumer's claim id
		// (the key under #components[].#claims, e.g. "db"), resolved by
		// FQN-equality between requiredClaims and #component.#claims.
		#statusWrites?: [claimId=string]: _

		output: _
	}
}

#ModuleTransformer: {
	apiVersion: "opmodel.dev/core/v1alpha2"
	kind:       "ModuleTransformer"
	metadata: {
		modulePath!:  #ModulePathType
		version!:     #MajorVersionType
		name!:        #NameType
		fqn!:         #FQNType
		description?: string
	}
	requiredLabels?: #LabelsAnnotationsType
	optionalLabels?: #LabelsAnnotationsType
	requiredClaims?: [FQN=string]: _
	optionalClaims?: [FQN=string]: _

	// Pre-fire gate (TR-D7). Conjunction over resources AND traits AND claims.
	// If declared and #AnyComponentMatches returns false, the transformer
	// does not fire. Body iterates components itself; this is purely a gate.
	requiresComponents?: {
		resources?: [FQN=string]: _
		traits?: [FQN=string]:    _
		claims?: [FQN=string]:    _
	}

	readsContext?: [...string]
	producesKinds?: [...string]

	// #transform body — module-scope. NO #component slot; the body iterates
	// #moduleRelease.#components itself.
	#transform?: {
		#moduleRelease: _
		#context:       #TransformerContext
		#statusWrites?: [claimId=string]: _
		output: _
	}
}

#TransformerMap: [#FQNType]: #ComponentTransformer | #ModuleTransformer

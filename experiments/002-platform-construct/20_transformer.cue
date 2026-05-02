package platform_construct

// Two-primitive transformer split (014 D17 + 015 TR-D5).
//
// #ComponentTransformer carries match-keys + a #transform body that the
// pure-CUE matcher in 25_render.cue unifies with concrete inputs to produce
// the render output. The body shape (#moduleRelease + #component + #context
// + output) honours the D18 runtime guarantee: every #transform invocation
// receives a fully concrete #ModuleRelease and a singular #Component.
//
// readsContext / producesKinds are catalog-UI hints (014/03-schema.md);
// they don't influence the matcher.

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

	// #transform body. Three open input fields the dispatcher unifies in
	// concretely, plus an `output: _` slot the rendering body fills. The
	// inputs are plain (no `!`) — under strict mode unfilled-required would
	// make `t.#transform != _|_` false at fixture time and silently drop
	// the transformer from the dispatcher's loop in 25_render.cue.
	#transform?: {
		#moduleRelease: _
		#component:     _
		#context:       #TransformerContext
		output:         _
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
	requiresComponents?: {
		resources?: [FQN=string]: _
		traits?: [FQN=string]:    _
		claims?: [FQN=string]:    _
	}
}

#TransformerMap: [#FQNType]: #ComponentTransformer | #ModuleTransformer

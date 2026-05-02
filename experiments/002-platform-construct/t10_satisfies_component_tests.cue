@if(test)

package platform_construct

// T10 — #SatisfiesComponent predicate (014 D17 + 014/05 satisfiesComponent
// pseudocode, expressed in pure CUE). The predicate is the building block
// the dispatch in 25_render.cue consumes; verifying it in isolation makes
// every dispatch failure traceable to either the predicate or the loop
// shape, never both.
//
// Each case unifies #SatisfiesComponent with a transformer + component
// fixture and asserts _ok matches expectation.

// ---- Inline transformer fixtures (narrow shapes — only the match-key
// fields the predicate inspects, no #transform body needed for predicate
// tests). ----

_t10_labelsOnlyTransformer: {
	requiredLabels: "core.opmodel.dev/workload-type": "stateless"
}

_t10_resourcesOnlyTransformer: {
	requiredResources: (_containerResource.metadata.fqn): _
}

_t10_traitsOnlyTransformer: {
	requiredTraits: (_exposeTrait.metadata.fqn): _
}

_t10_combinedTransformer: {
	requiredLabels: "tier":                               "web"
	requiredResources: (_containerResource.metadata.fqn): _
	requiredTraits: (_exposeTrait.metadata.fqn):          _
}

// ---- Inline component fixtures ----

_t10_bareComponent: {
	metadata: name: "bare"
}

_t10_labelledComponent: {
	metadata: {
		name: "labelled"
		labels: "core.opmodel.dev/workload-type": "stateless"
	}
}

_t10_wrongLabelComponent: {
	metadata: {
		name: "wrong"
		labels: "core.opmodel.dev/workload-type": "stateful"
	}
}

_t10_containerComponent: {
	metadata: name:                                "container-only"
	#resources: (_containerResource.metadata.fqn): _
}

_t10_exposeOnlyComponent: {
	metadata: name:                       "expose-only"
	#traits: (_exposeTrait.metadata.fqn): _
}

_t10_richComponent: {
	metadata: {
		name: "rich"
		labels: "tier": "web"
	}
	#resources: (_containerResource.metadata.fqn): _
	#traits: (_exposeTrait.metadata.fqn):          _
}

// ---- Cases ----

// Labels-only: passes when the label is present with the right value;
// fails on missing or mismatched.
t10_labelsOk: true & (#SatisfiesComponent & {
	transformer: _t10_labelsOnlyTransformer
	component:   _t10_labelledComponent
})._ok

t10_labelsMissing: false & (#SatisfiesComponent & {
	transformer: _t10_labelsOnlyTransformer
	component:   _t10_bareComponent
})._ok

t10_labelsWrongValue: false & (#SatisfiesComponent & {
	transformer: _t10_labelsOnlyTransformer
	component:   _t10_wrongLabelComponent
})._ok

// Resources-only: passes when the FQN is in #resources; fails when absent.
t10_resourcesOk: true & (#SatisfiesComponent & {
	transformer: _t10_resourcesOnlyTransformer
	component:   _t10_containerComponent
})._ok

t10_resourcesMissing: false & (#SatisfiesComponent & {
	transformer: _t10_resourcesOnlyTransformer
	component:   _t10_bareComponent
})._ok

// Traits-only: passes when the trait FQN is present; fails when absent.
t10_traitsOk: true & (#SatisfiesComponent & {
	transformer: _t10_traitsOnlyTransformer
	component:   _t10_exposeOnlyComponent
})._ok

t10_traitsMissing: false & (#SatisfiesComponent & {
	transformer: _t10_traitsOnlyTransformer
	component:   _t10_bareComponent
})._ok

// Combined: passes only when all three axes (label / resource / trait) hold.
t10_combinedOk: true & (#SatisfiesComponent & {
	transformer: _t10_combinedTransformer
	component:   _t10_richComponent
})._ok

t10_combinedMissingResource: false & (#SatisfiesComponent & {
	transformer: _t10_combinedTransformer
	component:   _t10_exposeOnlyComponent // has trait + nothing else
})._ok

// Empty transformer (no required* keys) → matches anything.
t10_emptyTransformerMatchesEverything: true & (#SatisfiesComponent & {
	transformer: {}
	component: _t10_bareComponent
})._ok

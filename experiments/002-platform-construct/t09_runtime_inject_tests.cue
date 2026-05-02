@if(test)

package platform_construct

// T09 — Runtime FillPath simulation. Static + runtime writes to the same
// #registry[Id] unify when fields are disjoint or values agree. Anchors
// 014 D2 (registry fillable from both sources via the same field) and the
// happy-path half of D15 (concurrent writes that don't conflict).

// Static portion of the platform — admin authors `opm-core` registration
// with curated `presentation` metadata.
_t09_static: #Platform & {
	metadata: name: "runtime-inject"
	type: "kubernetes"
	#registry: {
		"opm-core": {
			presentation: {
				category:    "core"
				description: "OPM core catalog"
			}
		}
	}
}

// Runtime portion — opm-operator FillPaths the #module value into
// #registry["opm-core"].#module after reconciling a ModuleRelease CR.
// Simulated by a second value unified with _t09_static.
_t09_runtime: #Platform & {
	metadata: name: "runtime-inject"
	type: "kubernetes"
	#registry: {
		"opm-core": {#module: _opmCoreModule}
	}
}

// Final platform = static & runtime.
_t09_unified: _t09_static & _t09_runtime

// Both writes survived: presentation from static, #module from runtime.
t09_presentationCategory: "core" & _t09_unified.#registry."opm-core".presentation.category
t09_moduleFqn:            "opmodel.dev/opm/v1alpha2/opm-kubernetes-core:0.1.0" & _t09_unified.#registry."opm-core".#module.metadata.fqn

// Computed views fire correctly off the merged value.
t09_knownResourcesCount: 2 & len(_t09_unified.#knownResources)
t09_transformersCount:   2 & len(_t09_unified.#composedTransformers)

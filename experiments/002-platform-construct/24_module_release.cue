package platform_construct

// #ModuleRelease — thin wrapper that pairs a #Module with deploy-time
// identity (release name + namespace). Real schema lives in 016 (and uses
// #ContextBuilder to compute #ctx + per-component #names); the experiment
// stays self-contained and only models what the slim render pipeline needs:
//
//   - #module     — the (fully concrete, per 014 D18) Module value
//   - name        — release name (used in metadata.name interpolation)
//   - namespace   — namespace the rendered manifests target
//   - uuid?       — release identity carrier (optional in the experiment)
//
// The matcher in 25_render.cue treats `#moduleRelease` as the input it
// receives — `#moduleRelease.#module.#components` is the iteration target.
#ModuleRelease: {
	#module!:   #Module
	name!:      #NameType
	namespace!: #NameType
	uuid?:      #UUIDType
}

@if(test)

package platform_construct

// T02 — A #Platform with a single static registration. Anchors D2 (registry
// fillable from CUE), D11 (registration is pure projection of #defines),
// and D16 (kebab-case Id keys).

_t02_platform: #Platform & {
	metadata: name: "single-reg"
	type: "kubernetes"
	#registry: {
		"opm-core": {#module: _opmCoreModule}
	}
}

t02_registryHasOne: len(_t02_platform.#registry) & 1
t02_entryEnabled:   true & _t02_platform.#registry."opm-core".enabled
t02_moduleFqnEcho:  _t02_platform.#registry."opm-core".#module.metadata.fqn & "opmodel.dev/opm/v1alpha2/opm-kubernetes-core:0.1.0"

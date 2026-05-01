@if(test)

package module_context

// T01 — Default cluster.domain falls back to "cluster.local" when neither
// platform nor environment overrides it. Anchors D8.

_t01_release: #ModuleRelease & {
	metadata: {
		name:      "rel1"
		namespace: "tmp"
		uuid:      "00000000-0000-0000-0000-000000000101"
	}
	#env:    _envNoRoute
	#module: _moduleDemo
	values: {}
}

t01_clusterDomain: _t01_release.#resolvedCtx.runtime.cluster.domain & "cluster.local"

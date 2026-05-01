@if(test)

package module_context

// T02 — Layer hierarchy: env cluster.domain wins over platform; release
// metadata.namespace wins over env default. Anchors D24.

// Case A — env does NOT override cluster, so platform's value wins.
_t02a_release: #ModuleRelease & {
	metadata: {
		name:      "rel-a"
		namespace: "ns-a"
		uuid:      "00000000-0000-0000-0000-000000000201"
	}
	#env:    _envDev // platform=_platformKind cluster=cluster.local; env adds no cluster override
	#module: _moduleDemo
	values: {}
}

t02a_clusterDomain: _t02a_release.#resolvedCtx.runtime.cluster.domain & "cluster.local"

// Case B — env explicitly overrides cluster.domain. Platform default loses.
_t02b_release: #ModuleRelease & {
	metadata: {
		name:      "rel-b"
		namespace: "ns-b"
		uuid:      "00000000-0000-0000-0000-000000000202"
	}
	#env:    _envClusterOverride // platform=_platformAltDomain (k8s.local); env overrides to internal.example.net
	#module: _moduleDemo
	values: {}
}

t02b_clusterDomain: _t02b_release.#resolvedCtx.runtime.cluster.domain & "internal.example.net"

// Case C — release.metadata.namespace overrides env default ("dev").
_t02c_release: #ModuleRelease & {
	metadata: {
		name:      "rel-c"
		namespace: "custom-ns"
		uuid:      "00000000-0000-0000-0000-000000000203"
	}
	#env:    _envDev // env default namespace is "dev"
	#module: _moduleDemo
	values: {}
}

t02c_namespace: _t02c_release.#resolvedCtx.runtime.release.namespace & "custom-ns"

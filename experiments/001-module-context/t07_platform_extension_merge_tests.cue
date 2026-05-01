@if(test)

package module_context

// T07 — Platform-extension merge: #ctx.platform unifies open-struct extensions
// from BOTH #Platform.#ctx.platform and #Environment.#ctx.platform.
// Anchors D3, D28.

// Case A — env_dev: platform supplies defaultStorageClass, env adds appDomain.
_t07a_release: #ModuleRelease & {
	metadata: {
		name:      "rel-a"
		namespace: "ns-a"
		uuid:      "00000000-0000-0000-0000-000000000701"
	}
	#env:    _envDev
	#module: _moduleDemo
	values: {}
}

t07a_storageClass: _t07a_release.#resolvedCtx.platform.defaultStorageClass & "rook-ceph"
t07a_appDomain:    _t07a_release.#resolvedCtx.platform.appDomain & "dev.example.com"

// Case B — env_prod: env contributes a structured extension (tls.issuers list).
_t07b_release: #ModuleRelease & {
	metadata: {
		name:      "rel-b"
		namespace: "ns-b"
		uuid:      "00000000-0000-0000-0000-000000000702"
	}
	#env:    _envProd
	#module: _moduleDemo
	values: {}
}

t07b_storageClass:  _t07b_release.#resolvedCtx.platform.defaultStorageClass & "rook-ceph"
t07b_appDomain:     _t07b_release.#resolvedCtx.platform.appDomain & "example.com"
t07b_tls_issuers_0: _t07b_release.#resolvedCtx.platform.tls.issuers[0] & "letsencrypt-prod"

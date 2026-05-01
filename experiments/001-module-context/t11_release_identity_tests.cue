@if(test)

package module_context

// T11 — Layer 3 release identity. #ctx.runtime.release.{name,namespace,uuid}
// and #ctx.runtime.module.{name,version,fqn,uuid} populate verbatim from
// the #ModuleRelease + #Module inputs.

_t11_release: #ModuleRelease & {
	metadata: {
		name:      "alpha"
		namespace: "demo"
		uuid:      "00000000-0000-0000-0000-000000001101"
	}
	#env:    _envDev
	#module: _moduleDemo
	values: {}
}

t11_release_name:      _t11_release.#resolvedCtx.runtime.release.name & "alpha"
t11_release_namespace: _t11_release.#resolvedCtx.runtime.release.namespace & "demo"
t11_release_uuid:      _t11_release.#resolvedCtx.runtime.release.uuid & "00000000-0000-0000-0000-000000001101"

t11_module_name:    _t11_release.#resolvedCtx.runtime.module.name & "demo"
t11_module_version: _t11_release.#resolvedCtx.runtime.module.version & "0.1.0"
t11_module_fqn:     _t11_release.#resolvedCtx.runtime.module.fqn & "opmodel.dev/experiments/modules/demo:0.1.0"
t11_module_uuid:    _t11_release.#resolvedCtx.runtime.module.uuid & "00000000-0000-0000-0000-000000000010"

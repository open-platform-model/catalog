@if(test)

package module_context

// T06 — #names injection lock-step. The #names field on each #Component must
// equal #ctx.runtime.components[<key>] — single source of truth via the
// _componentNames let binding in #ContextBuilder. Anchors D32.

_t06_release: #ModuleRelease & {
	metadata: {
		name:      "rel"
		namespace: "ns"
		uuid:      "00000000-0000-0000-0000-000000000601"
	}
	#env:    _envDev
	#module: _moduleDemo
	values: {}
}

// Pick router (default name) — assert each field of #names equals the matching
// #ctx.runtime.components.router field. We use field-by-field unification
// because direct struct-equality has no native operator in CUE.

t06_router_resourceName_match: _t06_release.components.router.#names.resourceName &
	_t06_release.#resolvedCtx.runtime.components.router.resourceName

t06_router_dns_fqdn_match: _t06_release.components.router.#names.dns.fqdn &
	_t06_release.#resolvedCtx.runtime.components.router.dns.fqdn

// Pick worker (override) — same lock-step expectation, but on the overridden value.
t06_worker_resourceName_match: _t06_release.components.worker.#names.resourceName &
	_t06_release.#resolvedCtx.runtime.components.worker.resourceName

t06_worker_dns_fqdn_match: _t06_release.components.worker.#names.dns.fqdn &
	_t06_release.#resolvedCtx.runtime.components.worker.dns.fqdn

// Belt-and-braces: assert the actual concrete values too, so a successful
// unification on TWO undefined fields can't accidentally pass.
t06_router_fqdn_concrete: _t06_release.components.router.#names.dns.fqdn & "rel-router.ns.svc.cluster.local"
t06_worker_fqdn_concrete: _t06_release.components.worker.#names.dns.fqdn & "wkr.ns.svc.cluster.local"

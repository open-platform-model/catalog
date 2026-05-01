@if(test)

package module_context

// T04 — Default ComponentNames cascade. Component without metadata.resourceName
// gets "{release}-{component}" base name; all four DNS variants derive from it.
// Anchors D10.

_t04_release: #ModuleRelease & {
	metadata: {
		name:      "rel"
		namespace: "ns"
		uuid:      "00000000-0000-0000-0000-000000000401"
	}
	#env:    _envDev
	#module: _moduleDemo
	values: {}
}

// "router" component has no resourceName override → defaults to "rel-router".
t04_router_resourceName: _t04_release.#resolvedCtx.runtime.components.router.resourceName & "rel-router"

t04_router_dns_local:      _t04_release.#resolvedCtx.runtime.components.router.dns.local & "rel-router"
t04_router_dns_namespaced: _t04_release.#resolvedCtx.runtime.components.router.dns.namespaced & "rel-router.ns"
t04_router_dns_svc:        _t04_release.#resolvedCtx.runtime.components.router.dns.svc & "rel-router.ns.svc"
t04_router_dns_fqdn:       _t04_release.#resolvedCtx.runtime.components.router.dns.fqdn & "rel-router.ns.svc.cluster.local"

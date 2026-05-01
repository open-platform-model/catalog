@if(test)

package module_context

// T05 — metadata.resourceName override on #Component cascades through all
// four DNS variants without per-variant changes. Anchors D13.

_t05_release: #ModuleRelease & {
	metadata: {
		name:      "rel"
		namespace: "ns"
		uuid:      "00000000-0000-0000-0000-000000000501"
	}
	#env:    _envDev
	#module: _moduleDemo
	values: {}
}

// "worker" component sets metadata.resourceName: "wkr" in _moduleDemo.
t05_worker_resourceName: _t05_release.#resolvedCtx.runtime.components.worker.resourceName & "wkr"

t05_worker_dns_local:      _t05_release.#resolvedCtx.runtime.components.worker.dns.local & "wkr"
t05_worker_dns_namespaced: _t05_release.#resolvedCtx.runtime.components.worker.dns.namespaced & "wkr.ns"
t05_worker_dns_svc:        _t05_release.#resolvedCtx.runtime.components.worker.dns.svc & "wkr.ns.svc"
t05_worker_dns_fqdn:       _t05_release.#resolvedCtx.runtime.components.worker.dns.fqdn & "wkr.ns.svc.cluster.local"

// And confirm the sibling component without override is unaffected.
t05_router_resourceName: _t05_release.#resolvedCtx.runtime.components.router.resourceName & "rel-router"

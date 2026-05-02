@if(test)

package claims

// T08 — CL-D15/D16 module-scope half: #ModuleTransformer's #statusWrites.
// _dnsHostnameTransformer matches against #moduleRelease.#module.#claims
// (no per-component scope), writes #statusWrites.<id>.fqdn. Phase 3 injects
// into module-level claim's #status.

_t08_platform: #Platform & {
	metadata: name: "t08"
	type: "kubernetes"
	#registry: {
		"opm-core": {#module: _opmCoreModule}
		"postgres": {#module: _postgresOperatorModule}
		"dns": {#module: _dnsModule}
	}
}

_t08_render: #PlatformRender & {
	#platform:      _t08_platform
	#moduleRelease: _withHostnameRelease
}

// Diagnostic surface.
t08_injectedFqdn: "ingress-app.example.com" & _t08_render.#status.injectedModule.edge.fqdn

// Materialised module-level claim status.
_t08_edgeStatus: _t08_render.#moduleReleaseWithStatus.#module.#claims.edge.#status
t08_statusFqdn:  "ingress-app.example.com" & _t08_edgeStatus.fqdn

// Module-scope writeback didn't pollute component-scope claims.
t08_componentDbHost: "demo-web-db.apps.svc.cluster.local" & _t08_render.#moduleReleaseWithStatus.#module.#components.web.#claims.db.#status.host

@if(test)

package claims

// T07 — CL-D15/D16: component-scope #statusWrites injection.
// Postgres transformer fires against web's db claim and emits
// #statusWrites: db: { host, port, secretName }. Phase 3 of the render
// pipeline injects those values into the claim's #status field by
// unification. Asserts both:
//   - The diagnostic surface (#status.injectedComponent) reports the
//     writeback.
//   - The materialised #moduleReleaseWithStatus carries the values at
//     #components.web.#claims.db.#status.

_t07_platform: #Platform & {
	metadata: name: "t07"
	type: "kubernetes"
	#registry: {
		"opm-core": {#module: _opmCoreModule}
		"postgres": {#module: _postgresOperatorModule}
	}
}

_t07_render: #PlatformRender & {
	#platform:      _t07_platform
	#moduleRelease: _webAppRelease
}

// Diagnostic projection.
t07_injectedHost: "demo-web-db.apps.svc.cluster.local" & _t07_render.#status.injectedComponent.web.db.host
t07_injectedPort: 5432 & _t07_render.#status.injectedComponent.web.db.port
t07_injectedSec:  "demo-web-db-credentials" & _t07_render.#status.injectedComponent.web.db.secretName

// Materialised #moduleReleaseWithStatus.
_t07_dbStatus: _t07_render.#moduleReleaseWithStatus.#module.#components.web.#claims.db.#status

t07_statusHost: "demo-web-db.apps.svc.cluster.local" & _t07_dbStatus.host
t07_statusPort: 5432 & _t07_dbStatus.port
t07_statusSec:  "demo-web-db-credentials" & _t07_dbStatus.secretName

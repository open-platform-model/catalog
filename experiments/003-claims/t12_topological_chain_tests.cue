@if(test)

package claims

// T12 — Topological correctness for depth-1 chains.
//
// Two transformers fire against the same component:
//   - _pgManagedDatabaseTransformer writes #statusWrites.db.{host, port, ...}
//   - _deploymentTransformer reads #component.#claims.db.#status.{host, port}
//     when present.
//
// The render pipeline (25_render.cue) computes #statusWrites in Phase 1
// (BASE dispatch, no #status reads), injects in Phase 3, and re-dispatches
// in Phase 4. Phase 4 sees the populated status, so the deployment's env
// vars resolve correctly.
//
// This test makes the writer/reader chain explicit: assert that BOTH the
// raw injected status (intermediate value) AND the rendered Deployment env
// (downstream value) reflect the same chain.

_t12_platform: #Platform & {
	metadata: name: "t12"
	type: "kubernetes"
	#registry: {
		"opm-core": {#module: _opmCoreModule}
		"postgres": {#module: _postgresOperatorModule}
	}
}

_t12_render: #PlatformRender & {
	#platform:      _t12_platform
	#moduleRelease: _webAppRelease
}

// Writer side: postgres put db.host into injectedComponent.
t12_writerHost: "demo-web-db.apps.svc.cluster.local" & _t12_render.#status.injectedComponent.web.db.host

// Reader side: deployment env var matches.
_t12_deployment: _t12_render.#outputs["opmodel.dev/opm/v1alpha2/providers/kubernetes/deployment-transformer@v1/web"]
_t12_envHost:    _t12_deployment.spec.template.spec.containers[0].env[0].value

t12_readerHost: "demo-web-db.apps.svc.cluster.local" & _t12_envHost

// Equality of writer + reader values (the chain held).
t12_chainConsistent: _t12_render.#status.injectedComponent.web.db.host & _t12_envHost

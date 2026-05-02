@if(test)

package claims

// T09 — End-to-end status consumption (CL-D15 cross-runtime portability).
// _deploymentTransformer's body reads #component.#claims.db.#status.host
// to populate the container's DATABASE_HOST env var. Postgres transformer
// writes that host. Both fire in the same render — Phase 4 sees the
// post-injection #moduleReleaseWithStatus with concrete status values.

_t09_platform: #Platform & {
	metadata: name: "t09"
	type: "kubernetes"
	#registry: {
		"opm-core": {#module: _opmCoreModule}
		"postgres": {#module: _postgresOperatorModule}
	}
}

_t09_render: #PlatformRender & {
	#platform:      _t09_platform
	#moduleRelease: _webAppRelease
}

_t09_deployment: _t09_render.#outputs["opmodel.dev/opm/v1alpha2/providers/kubernetes/deployment-transformer@v1/web"]

// First env entry = DATABASE_HOST = postgres-written value.
_t09_envFirst:    _t09_deployment.spec.template.spec.containers[0].env[0]
t09_envHostName:  "DATABASE_HOST" & _t09_envFirst.name
t09_envHostValue: "demo-web-db.apps.svc.cluster.local" & _t09_envFirst.value

// Second env entry = DATABASE_PORT = "5432".
_t09_envSecond:   _t09_deployment.spec.template.spec.containers[0].env[1]
t09_envPortName:  "DATABASE_PORT" & _t09_envSecond.name
t09_envPortValue: "5432" & _t09_envSecond.value

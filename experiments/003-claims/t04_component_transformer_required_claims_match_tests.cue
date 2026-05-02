@if(test)

package claims

// T04 — TR-D5 component half + 014/05 satisfiesComponent extended with
// requiredClaims. _pgManagedDatabaseTransformer fires against the `web`
// component because web.#claims.db.metadata.fqn == requiredClaims key.

_t04_platform: #Platform & {
	metadata: name: "t04"
	type: "kubernetes"
	#registry: {
		"opm-core": {#module: _opmCoreModule}
		"postgres": {#module: _postgresOperatorModule}
	}
}

_t04_render: #PlatformRender & {
	#platform:      _t04_platform
	#moduleRelease: _webAppRelease
}

// _componentFiresBase is the canonical "did it fire" surface (Phase 1).
// Convert to a set for membership checks.
_t04_fires: {
	for k, _ in _t04_render._componentFiresBase {(k): _}
}

// Postgres fired against web.
t04_pgFired: true & (_t04_fires["vendor.com/postgres-operator/managed-database-transformer@v1/web"] != _|_)

// Deployment fired against web (resource match).
t04_deployFired: true & (_t04_fires["opmodel.dev/opm/v1alpha2/providers/kubernetes/deployment-transformer@v1/web"] != _|_)

// Service fired against web (trait match).
t04_serviceFired: true & (_t04_fires["opmodel.dev/opm/v1alpha2/providers/kubernetes/service-transformer@v1/web"] != _|_)

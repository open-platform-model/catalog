@if(test)

package platform_construct

// T12 — End-to-end: registry → composedTransformers → matcher dispatch →
// rendered #outputs. Uses the full opm-core + postgres registration so the
// platform is realistic; only ComponentTransformers fire (postgres' is a
// component-scope ManagedDatabase fulfiller — the consumer's #claims.db
// instance lives at component-scope on `web`, but its rendering would need
// 015's #statusWrites pipeline; here it's enough that the dispatch
// completes cleanly without that 015 surface).
//
// _pipelineFixture doubles as the manual-inspection target:
//
//   cue eval -e '_pipelineFixture.#outputs' -t test ./...
//
// dumps the rendered K8s manifest set so a reader can see exactly what the
// pure-CUE matcher dispatch produces.

_pipelineFixture: {
	platform: #Platform & {
		metadata: name: "showcase"
		type: "kubernetes"
		#registry: {
			"opm-core": {#module: _opmCoreModule}
			"postgres": {#module: _postgresOperatorModule}
		}
	}

	render: #PlatformRender & {
		#platform:      platform
		#moduleRelease: _webAppRelease
	}

	#outputs: render.#outputs
}

// ---- Bundle is non-empty ----
t12_outputsNonEmpty: true & (len(_pipelineFixture.#outputs) > 0)

// ---- Both component-scope renderers fired against `web` ----
t12_deploymentForWeb: true & (_pipelineFixture.#outputs["opmodel.dev/opm/v1alpha2/providers/kubernetes/deployment-transformer@v1/web"] != _|_)
t12_serviceForWeb:    true & (_pipelineFixture.#outputs["opmodel.dev/opm/v1alpha2/providers/kubernetes/service-transformer@v1/web"] != _|_)

// ---- Manifest fidelity end-to-end: namespace + name reflect the release.
t12_deploymentNamespace: "apps" & _pipelineFixture.#outputs["opmodel.dev/opm/v1alpha2/providers/kubernetes/deployment-transformer@v1/web"].metadata.namespace
t12_serviceNamespace:    "apps" & _pipelineFixture.#outputs["opmodel.dev/opm/v1alpha2/providers/kubernetes/service-transformer@v1/web"].metadata.namespace

// ---- Postgres transformer is registered but does NOT appear in #outputs.
//
// 014's matcher only handles Resource / Trait demand; the postgres
// transformer requires a Claim FQN, which is 015 territory. The dispatch
// in 25_render.cue iterates ComponentTransformers and tests resource /
// trait satisfaction — postgres' requiredClaims is not consulted, so it
// never fires. Verifying the absence proves 014's scope boundary.
t12_postgresAbsent: true & (_pipelineFixture.#outputs["vendor.com/postgres-operator/managed-database-transformer@v1/web"] == _|_)

@if(test)

package claims

// T13 — Full pipeline showcase. All four catalog modules registered + the
// hostname-bearing consumer module. Asserts the rendered manifest set
// covers component-scope render (Deployment, Service, Postgres CR) and
// module-scope render (DNS Record). Doubles as the eval target:
//
//   cue eval -e '_pipelineFixture.#outputs' -t test ./...

_pipelineFixture: #PlatformRender & {
	#platform: #Platform & {
		metadata: name: "full-pipeline"
		type: "kubernetes"
		#registry: {
			"opm-core": {#module: _opmCoreModule}
			"postgres": {#module: _postgresOperatorModule}
			"k8up": {#module: _k8upModule}
			"dns": {#module: _dnsModule}
		}
	}
	#moduleRelease: _withHostnameRelease
}

// Outputs cover all four transformer kinds firing for this release:
//   - Deployment (deployment-transformer / web)
//   - Service    (service-transformer / web)
//   - Postgres   (managed-database-transformer / web)
//   - DNS Record (hostname-transformer)
t13_outputCount: 4 & len([for k, _ in _pipelineFixture.#outputs {k}])

t13_deploymentPresent: true & (_pipelineFixture.#outputs["opmodel.dev/opm/v1alpha2/providers/kubernetes/deployment-transformer@v1/web"] != _|_)
t13_servicePresent:    true & (_pipelineFixture.#outputs["opmodel.dev/opm/v1alpha2/providers/kubernetes/service-transformer@v1/web"] != _|_)
t13_postgresPresent:   true & (_pipelineFixture.#outputs["vendor.com/postgres-operator/managed-database-transformer@v1/web"] != _|_)
t13_dnsPresent:        true & (_pipelineFixture.#outputs["opmodel.dev/dns/v1alpha2/transformers/hostname-transformer@v1"] != _|_)

// Status writebacks for both scopes are visible.
t13_componentDbHost: "demo-web-db.apps.svc.cluster.local" & _pipelineFixture.#status.injectedComponent.web.db.host
t13_moduleEdgeFqdn:  "ingress-app.example.com" & _pipelineFixture.#status.injectedModule.edge.fqdn

// Deployment reads the postgres host through the chain.
t13_envHost: "demo-web-db.apps.svc.cluster.local" & _pipelineFixture.#outputs["opmodel.dev/opm/v1alpha2/providers/kubernetes/deployment-transformer@v1/web"].spec.template.spec.containers[0].env[0].value

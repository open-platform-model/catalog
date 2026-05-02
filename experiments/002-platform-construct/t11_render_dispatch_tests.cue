@if(test)

package platform_construct

// T11 — #PlatformRender dispatch (014 D17 + D18 + 014/05 matchAndRender,
// expressed in pure CUE). Smaller scope than t12: only the OPM core module
// is registered (so no postgres / k8up noise). The web component carries
// both a Container resource and an Expose trait, so both transformers fire.
//
// Keys in #outputs follow the convention "<transformerFqn>/<componentName>".

_t11_platform: #Platform & {
	metadata: name: "render-test"
	type: "kubernetes"
	#registry: {
		"opm-core": {#module: _opmCoreModule}
	}
}

_t11_render: #PlatformRender & {
	#platform:      _t11_platform
	#moduleRelease: _webAppRelease
}

// ---- Bundle key set ----

// 2 outputs: deployment for web + service for web.
t11_outputCount: 2 & len(_t11_render.#outputs)

// Deployment key present.
t11_deploymentPresent: true & (_t11_render.#outputs["opmodel.dev/opm/v1alpha2/providers/kubernetes/deployment-transformer@v1/web"] != _|_)

// Service key present.
t11_servicePresent: true & (_t11_render.#outputs["opmodel.dev/opm/v1alpha2/providers/kubernetes/service-transformer@v1/web"] != _|_)

// ---- Manifest fidelity (D18 — concrete inputs flow through the body) ----

_t11_deployment: _t11_render.#outputs["opmodel.dev/opm/v1alpha2/providers/kubernetes/deployment-transformer@v1/web"]

t11_deploymentApiVersion:    "apps/v1" & _t11_deployment.apiVersion
t11_deploymentKind:          "Deployment" & _t11_deployment.kind
t11_deploymentName:          "demo-web" & _t11_deployment.metadata.name
t11_deploymentNamespace:     "apps" & _t11_deployment.metadata.namespace
t11_deploymentReplicas:      2 & _t11_deployment.spec.replicas
t11_deploymentImage:         "nginx:1.27" & _t11_deployment.spec.template.spec.containers[0].image
t11_deploymentContainerPort: 8080 & _t11_deployment.spec.template.spec.containers[0].ports[0].containerPort

_t11_service: _t11_render.#outputs["opmodel.dev/opm/v1alpha2/providers/kubernetes/service-transformer@v1/web"]

t11_serviceApiVersion: "v1" & _t11_service.apiVersion
t11_serviceKind:       "Service" & _t11_service.kind
t11_serviceName:       "demo-web" & _t11_service.metadata.name
t11_serviceNamespace:  "apps" & _t11_service.metadata.namespace
t11_servicePort:       8080 & _t11_service.spec.ports[0].port

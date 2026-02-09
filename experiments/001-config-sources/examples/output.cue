package examples

import (
	core "example.com/config-sources/core"
	k8s "example.com/config-sources/providers/kubernetes/transformers"
)

// Concrete K8s output for the web app example.
// Run: cue export ./examples/ -e k8sOutput --out yaml
_ctx: core.#TransformerContext & {
	#moduleMetadata: {
		name:    "web-app-module"
		version: "0.1.0"
		labels: {}
	}
	#componentMetadata: webAppComponent.metadata
	name:               "web-app-prod"
	namespace:          "production"
}

k8sOutput: {
	configSources: (k8s.#ConfigSourceTransformer.#transform & {
		#component: webAppComponent
		#context:   _ctx
	}).output

	deployment: (k8s.#DeploymentTransformer.#transform & {
		#component: webAppComponent
		#context:   _ctx
	}).output

	service: (k8s.#ServiceTransformer.#transform & {
		#component: webAppComponent
		#context:   _ctx
	}).output
}

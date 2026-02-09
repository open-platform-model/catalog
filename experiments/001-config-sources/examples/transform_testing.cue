package examples

import (
	core "example.com/config-sources/core"
	k8s_transformers "example.com/config-sources/providers/kubernetes/transformers"
)

/////////////////////////////////////////////////////////////////
//// Transform Verification
//// These validate at vet time that transforms produce valid output.
//// Use: cue vet ./... to verify
//// Use: cue export ./examples/ -e verifyConfigSource --out yaml
/////////////////////////////////////////////////////////////////

_transformCtx: core.#TransformerContext & {
	namespace: "production"
	labels: {
		"app": "web-app"
	}
	componentLabels: {
		"app.kubernetes.io/name": "web-app"
	}
}

// Validate config source transform
_verifyConfigSource: k8s_transformers.#ConfigSourceTransformer.#transform & {
	#component: webAppComponent
	#context:   _transformCtx
}

// Validate deployment transform (with env.from resolution)
_verifyDeployment: k8s_transformers.#DeploymentTransformer.#transform & {
	#component: webAppComponent
	#context:   _transformCtx
}

// Validate service transform
_verifyService: k8s_transformers.#ServiceTransformer.#transform & {
	#component: webAppComponent
	#context:   _transformCtx
}

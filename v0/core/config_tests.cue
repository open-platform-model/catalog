@if(test)

package core

// #Config Tests

_testConfigMinimal: #Config & {
	apiVersion: "opmodel.dev/core/v0"
	kind:       "Config"
}

_testConfigFull: #Config & {
	apiVersion: "opmodel.dev/core/v0"
	kind:       "Config"
	registry:   "registry.opmodel.dev:5000"
	cacheDir:   "/home/user/.opm/cache"
	providers: {
		kubernetes: {}
	}
	kubernetes: {
		kubeconfig: "/home/user/.kube/config"
		context:    "prod-cluster"
		namespace:  "default"
	}
}

_testConfigRegistryFormat: #Config & {
	apiVersion: "opmodel.dev/core/v0"
	kind:       "Config"
	registry:   "localhost:5000"
}

_testConfigRegistryNoDomain: #Config & {
	apiVersion: "opmodel.dev/core/v0"
	kind:       "Config"
	registry:   "opmodel.dev"
}

// Negative tests moved to testdata/*.yaml files

// #KubernetesConfig Tests

_testK8sConfigMinimal: #KubernetesConfig & {
	namespace: "default"
}

_testK8sConfigFull: #KubernetesConfig & {
	kubeconfig: "/custom/path/config"
	context:    "staging"
	namespace:  "my-app"
}

_testK8sConfigNamespaceHyphen: #KubernetesConfig & {
	namespace: "my-namespace-123"
}

// Negative tests moved to testdata/*.yaml files

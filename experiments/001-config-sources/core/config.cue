package core

// #Config: OPM CLI configuration schema
// Used by: ~/.opm/config.cue
// Validates: registry URL, cache path, kubernetes settings
#Config: close({
	apiVersion: "opmodel.dev/core/v0"
	kind:       "Config"

	// registry is the default registry for CUE module resolution.
	// Can be overridden by --registry flag or OPM_REGISTRY env var.
	registry?: string & =~"^[a-z0-9.-]+(:[0-9]+)?$"

	// cacheDir is the local cache directory path.
	// Can be overridden by OPM_CACHE_DIR env var.
	cacheDir?: string

	// providers maps provider aliases to their definitions.
	// Loaded from registry via CUE imports.
	providers?: [string]: _

	// kubernetes contains Kubernetes-specific settings.
	kubernetes?: #KubernetesConfig
})

#KubernetesConfig: close({
	// kubeconfig is the path to the kubeconfig file.
	kubeconfig?: string

	// context is the Kubernetes context to use.
	// Default: current-context from kubeconfig
	context?: string

	// namespace is the default namespace for operations.
	// Must be RFC-1123 compliant.
	namespace?: string & =~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
})

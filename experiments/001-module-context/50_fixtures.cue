package module_context

// Fixtures — concrete inputs reused across test files. Hidden (underscore prefix)
// so they do not appear in `cue export` output. Plain values, no @if(test) tag,
// so any non-test evaluation can still reference them if needed.

// Platform with default cluster.domain ("cluster.local") + a platform extension.
_platformKind: #Platform & {
	metadata: name: "kind-opm-dev"
	#ctx: {
		runtime: cluster: domain: "cluster.local"
		platform: {
			defaultStorageClass: "rook-ceph"
		}
	}
}

// Platform with non-default cluster.domain — used to prove env can override.
_platformAltDomain: #Platform & {
	metadata: name: "alt-domain"
	#ctx: {
		runtime: cluster: domain: "k8s.local"
		platform: {}
	}
}

// Environment "dev" — namespace "dev", route.domain "dev.example.com".
// No cluster.domain override (inherits from platform).
_envDev: #Environment & {
	metadata: name: "dev"
	#platform: _platformKind
	#ctx: {
		runtime: {
			release: namespace: "dev"
			route: domain:      "dev.example.com"
		}
		platform: {
			appDomain: "dev.example.com"
		}
	}
}

// Environment "prod" — namespace "prod", route.domain "example.com",
// adds an environment-only platform extension key.
_envProd: #Environment & {
	metadata: name: "prod"
	#platform: _platformKind
	#ctx: {
		runtime: {
			release: namespace: "prod"
			route: domain:      "example.com"
		}
		platform: {
			appDomain: "example.com"
			tls: issuers: ["letsencrypt-prod"]
		}
	}
}

// Environment with no route configured — used to prove route? is properly absent.
_envNoRoute: #Environment & {
	metadata: name: "no-route"
	#platform: _platformKind
	#ctx: {
		runtime: release: namespace: "tmp"
		platform: {}
	}
}

// Environment whose cluster.domain overrides the platform's — used in t02 to prove
// env wins on cluster.domain.
_envClusterOverride: #Environment & {
	metadata: name: "cluster-override"
	#platform: _platformAltDomain
	#ctx: {
		runtime: {
			release: namespace: "ovr"
			cluster: domain:    "internal.example.net"
			route: domain:      "ovr.example.com"
		}
		platform: {}
	}
}

// Demo module — two components, one with a resourceName override.
// "router" uses the default name; "worker" overrides to "wkr".
_moduleDemo: #Module & {
	metadata: {
		modulePath: "opmodel.dev/experiments/modules"
		name:       "demo"
		version:    "0.1.0"
		uuid:       "00000000-0000-0000-0000-000000000010"
	}
	#components: {
		router: {
			metadata: name: "router"
			spec: {}
		}
		worker: {
			metadata: {
				name:         "worker"
				resourceName: "wkr"
			}
			spec: {}
		}
	}
}

package module_context

// Lifted verbatim (modulo wording) from
// catalog/enhancements/016-module-context/03-schema.md.

// #ModuleContext: the value injected into #Module.#ctx by #ModuleRelease.
// Module authors read it inside #components; never assign it directly.
#ModuleContext: {
	runtime: #RuntimeContext
	platform: {...} // open struct, platform-team-owned
}

#RuntimeContext: {
	// Release identity — mirrors ModuleRelease.metadata.
	release: {
		name!:      #NameType
		namespace!: string
		uuid!:      #UUIDType
	}

	// Module identity — mirrors Module.metadata.
	module: {
		name!:    #NameType
		version!: #VersionType
		fqn!:     #ModuleFQNType
		uuid!:    #UUIDType
	}

	// Cluster environment.
	cluster: {
		// DNS search domain for Kubernetes Services.
		// Defaults to "cluster.local"; overridable via #Platform.#ctx and #Environment.#ctx.
		domain: *"cluster.local" | string
	}

	// Ingress/route environment — absent when no route domain is configured.
	route?: {
		domain: string
	}

	// Per-component computed names. One entry per component key in #Module.#components.
	components: [compName=string]: #ComponentNames & {
		_releaseName:   release.name
		_namespace:     release.namespace
		_clusterDomain: cluster.domain
		_compName:      compName
	}
}

#ComponentNames: {
	_releaseName:   string
	_namespace:     string
	_clusterDomain: string
	_compName:      string

	// Base Kubernetes resource name for all resources produced by this component.
	// Defaults to "{release}-{component}". Overridden when the component
	// sets metadata.resourceName — #ContextBuilder passes the override here.
	resourceName: string | *"\(_releaseName)-\(_compName)"

	dns: {
		local:      resourceName
		namespaced: "\(resourceName).\(_namespace)"
		svc:        "\(resourceName).\(_namespace).svc"
		fqdn:       "\(resourceName).\(_namespace).svc.\(_clusterDomain)"
	}
}

// #PlatformContext: the shape #Platform.#ctx resolves to.
#PlatformContext: {
	runtime: {
		cluster: {
			domain: *"cluster.local" | string
		}
		route?: {
			domain: string
		}
	}
	platform: {...}
}

// #EnvironmentContext: the shape #Environment.#ctx resolves to.
#EnvironmentContext: {
	runtime: {
		release: {
			// Default namespace for releases in this environment.
			// Individual ModuleReleases can override via metadata.namespace.
			namespace: string
		}
		cluster?: {
			domain: string
		}
		route?: {
			domain: string
		}
	}
	platform: {...}
}

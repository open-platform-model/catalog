package module_context

// #ContextBuilder: assembles #ModuleContext from layered inputs and the
// per-component #names injections.
// Invoked inline by #ModuleRelease via a let binding.
#ContextBuilder: {
	#release: {
		name:      #NameType
		namespace: string
		uuid:      #UUIDType
	}
	#module: {
		name:    #NameType
		version: #VersionType
		fqn:     #ModuleFQNType
		uuid:    #UUIDType
	}

	#components: [string]: _ // component key map; values inspected for metadata.resourceName
	#platform:    #Platform
	#environment: #Environment

	// Resolve cluster domain: environment override beats platform default.
	// #EnvironmentContext.runtime.cluster is optional, so guard with a
	// conditional struct rather than a `*` default disjunction (which would
	// fail when the env omits the cluster field).
	let _resolved = {
		domain: string
		if #environment.#ctx.runtime.cluster != _|_ {
			domain: #environment.#ctx.runtime.cluster.domain
		}
		if #environment.#ctx.runtime.cluster == _|_ {
			domain: #platform.#ctx.runtime.cluster.domain
		}
	}
	let _resolvedClusterDomain = _resolved.domain

	// Computed once, reused by both `ctx.runtime.components` and the
	// per-component `injections.<name>.#names` field below. Single source
	// of truth for resourceName / DNS variants (D32 lock-step).
	let _componentNames = {
		for compName, comp in #components {
			(compName): {
				_releaseName:   #release.name
				_namespace:     #release.namespace
				_clusterDomain: _resolvedClusterDomain
				_compName:      compName
				if comp.metadata.resourceName != _|_ {
					resourceName: comp.metadata.resourceName
				}
			}
		}
	}

	out: {
		ctx: #ModuleContext & {
			runtime: #RuntimeContext & {
				release: #release
				module:  #module
				cluster: domain: _resolvedClusterDomain

				if #environment.#ctx.runtime.route != _|_ {
					route: #environment.#ctx.runtime.route
				}

				components: _componentNames
			}

			// Merge platform extensions from both layers.
			platform: #platform.#ctx.platform & #environment.#ctx.platform
		}

		injections: {
			for compName, _ in #components {
				(compName): #names: _componentNames[compName]
			}
		}
	}
}

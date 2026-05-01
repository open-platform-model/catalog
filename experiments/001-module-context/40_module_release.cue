package module_context

// #ModuleRelease: invokes #ContextBuilder, unifies result back into the module.
// Stub form: only the surface needed to drive context resolution.
#ModuleRelease: {
	apiVersion: "opmodel.dev/experiments/module_context/v0"
	kind:       "ModuleRelease"

	metadata: {
		name!:      #NameType
		namespace!: string
		uuid!:      #UUIDType // passed in concretely; no SHA1 derivation (no stdlib)
	}

	#env: #Environment

	#module!: #Module
	values:   _

	// Unify #config: values FIRST. Modules may build #components dynamically
	// from #config (mc_java_fleet-style `for srv in #config.servers`); those
	// components only materialise once #config is concrete. Feeding the
	// builder the pre-config view loses the dynamic components.
	// (Finding vs. 03-schema.md's verbatim snippet — see README.)
	let _withConfig = #module & {#config: values}
	let _moduleMetadata = _withConfig.metadata
	let _moduleComponents = _withConfig.#components

	let _builderOut = (#ContextBuilder & {
		#release: {
			name:      metadata.name
			namespace: metadata.namespace
			uuid:      metadata.uuid
		}
		#module: {
			name:    _moduleMetadata.name
			version: _moduleMetadata.version
			fqn:     _moduleMetadata.fqn
			uuid:    _moduleMetadata.uuid
		}
		#components:  _moduleComponents
		#platform:    #env.#platform
		#environment: #env
	}).out

	let unifiedModule = _withConfig & {
		#ctx:        _builderOut.ctx
		#components: _builderOut.injections
	}

	components: {
		for name, comp in unifiedModule.#components {
			(name): comp
		}
	}

	// Re-export the resolved #ctx for tests that want to assert against it
	// without re-running the builder. CUE definition (#-prefixed) so it is
	// excluded from export, like #ctx itself, but is reachable through field
	// access in tests (hidden underscore fields are not always traversed by
	// `cue vet`'s concreteness check).
	#resolvedCtx: _builderOut.ctx
}

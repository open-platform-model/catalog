package module_context

// Stub #Module — only the surface the context-handling experiment needs.
// #defines / #claims (015), #policies, debugValues, label cascades omitted.
#Module: {
	apiVersion: "opmodel.dev/experiments/module_context/v0"
	kind:       "Module"

	metadata: {
		modulePath!: #ModulePathType
		name!:       #NameType
		version!:    #VersionType
		fqn:         #ModuleFQNType & "\(modulePath)/\(name):\(version)"
		uuid!:       #UUIDType // passed in concretely; no SHA1 derivation (no stdlib)

		defaultNamespace?: string
		description?:      string
	}

	#components: [Id=string]: #Component & {
		metadata: {
			name: string | *Id
		}
	}

	#config: _

	#ctx: #ModuleContext
}

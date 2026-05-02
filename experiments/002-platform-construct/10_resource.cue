package platform_construct

// Stub #Resource — only enough surface to populate #Module.#defines.resources
// and to verify FQN-binding + #Platform.#knownResources projection.
#Resource: {
	apiVersion!: string
	kind:        "Resource"
	metadata: {
		modulePath!:  #ModulePathType
		name!:        #NameType
		version!:     #MajorVersionType
		fqn!:         #FQNType
		description?: string
	}
	#spec?: _
}

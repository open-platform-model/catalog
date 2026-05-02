package claims

// Stub #Trait — same shape as #Resource for experiment purposes.
#Trait: {
	apiVersion!: string
	kind:        "Trait"
	metadata: {
		modulePath!:  #ModulePathType
		name!:        #NameType
		version!:     #MajorVersionType
		fqn!:         #FQNType
		description?: string
	}
	#spec?: _
}

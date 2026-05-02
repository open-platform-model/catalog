package platform_construct

// Stub #Claim — apiVersion + metadata.fqn + open #spec/#status.
// Sufficient for #Platform.#knownClaims projection and matcher index tests.
#Claim: {
	apiVersion!: string
	kind:        "Claim"
	metadata: {
		modulePath!:  #ModulePathType
		name!:        #NameType
		version!:     #MajorVersionType
		fqn!:         #FQNType
		description?: string
	}
	#spec?:   _
	#status?: _
}

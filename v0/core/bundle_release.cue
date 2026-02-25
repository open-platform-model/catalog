package core

// #BundleRelease: The concrete deployment instance
// Contains: Reference to Bundle, concrete values (closed)
// Users/deployment systems create this to deploy a specific version
#BundleRelease: {
	apiVersion: "opmodel.dev/core/v0"
	kind:       "BundleRelease"

	metadata: {
		name!:        #NameType
		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	// Reference to the Bundle to deploy
	#bundle!: #Bundle

	// Concrete values (everything closed/concrete)
	// Must satisfy the value schema from #bundle
	values!: close(#bundle.#config)
}

#BundleReleaseMap: [string]: #BundleRelease

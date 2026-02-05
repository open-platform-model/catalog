package core

// #ModuleRelease: The concrete deployment instance
// Contains: Reference to Module, concrete values (closed), target namespace
// Users/deployment systems create this to deploy a specific version
#ModuleRelease: close({
	apiVersion: "opmodel.dev/core/v0"
	kind:       "ModuleRelease"

	metadata: {
		name!:        string
		namespace!:   string // Required for releases (target environment)
		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType

		fqn:     #module.metadata.fqn
		version: #module.metadata.version

		labels: {if #module.metadata.labels != _|_ {#module.metadata.labels}}
		annotations: {if #module.metadata.annotations != _|_ {#module.metadata.annotations}}
	}

	// Reference to the Module to deploy
	#module!: #Module

	// Components defined in this module release
	components: #module.#components

	// Module-level scopes (if any)
	scopes?: [Id=string]: #Scope
	if #module.#scopes != _|_ {
		scopes: #module.#scopes
	}

	// Concrete values (everything closed/concrete)
	// Must satisfy the value schema from #module
	values: close(#module.#config)
})

#ModuleReleaseMap: [string]: #ModuleRelease

_testModuleRelease: #ModuleRelease & {
	metadata: {
		name:      "test-release"
		namespace: "default"
	}

	#module: _testModule

	values: {
		replicaCount: 3
		image:        "nginx:latest"
	}
}

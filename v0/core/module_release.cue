package core

import (
	uid "uuid"
)

// #ModuleRelease: The concrete deployment instance
// Contains: Reference to Module, concrete values (closed), target namespace
// Users/deployment systems create this to deploy a specific version
#ModuleRelease: {
	apiVersion: "opmodel.dev/core/v0"
	kind:       "ModuleRelease"

	metadata: {
		name!:      #NameType
		namespace!: string // Required for releases (target environment)
		version:    #moduleMetadata.version
		uuid:       #UUIDType & uid.SHA1(OPMNamespace, "\(#moduleMetadata.fqn):\(name):\(namespace)")

		labels?: #LabelsAnnotationsType
		labels: {if #moduleMetadata.labels != _|_ {#moduleMetadata.labels}} & {
			// Standard labels for module release identification
			"module-release.opmodel.dev/name":    "\(name)"
			"module-release.opmodel.dev/version": "\(version)"
			"module-release.opmodel.dev/uuid":    "\(uuid)"
		}
		annotations?: #LabelsAnnotationsType
		annotations: {if #moduleMetadata.annotations != _|_ {#moduleMetadata.annotations}}

	}

	// Reference to the Module to deploy
	#module!:        #Module
	#moduleMetadata: #module.metadata

	// Concrete values for this release (everything closed/concrete)
	// Must satisfy the value schema from #module
	_#module: #module & {#config: values}

	// Components defined in this module release
	components: _#module.#components

	// Module-level policies (if any)
	policies?: [Id=string]: #Policy
	if _#module.#policies != _|_ {
		policies: _#module.#policies
	}

	// Concrete values (everything closed/concrete)
	// Must satisfy the value schema from #module
	values: close(#module.#config)
}

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

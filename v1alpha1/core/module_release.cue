package core

import (
	cue_uuid "uuid"
)

// #ModuleRelease: The concrete deployment instance
// Contains: Reference to Module, values, target namespace
// Users/deployment systems create this to deploy a specific version
#ModuleRelease: {
	apiVersion: "opmodel.dev/core/v1alpha1"
	kind:       "ModuleRelease"

	metadata: {
		name!:      #NameType
		namespace!: string // Required for releases (target environment)

		// Generate a stable UUID for this release based on the module's UUID, name, and namespace
		uuid: #UUIDType & cue_uuid.SHA1(OPMNamespace, "\(#moduleMetadata.uuid):\(name):\(namespace)")

		labels?: #LabelsAnnotationsType
		labels?: {if #moduleMetadata.labels != _|_ {#moduleMetadata.labels}}
		labels: {
			// Standard labels for module release identification
			"module-release.opmodel.dev/name": "\(name)"
			"module-release.opmodel.dev/uuid": "\(uuid)"
		}

		annotations?: #LabelsAnnotationsType
		annotations?: {if #moduleMetadata.annotations != _|_ {#moduleMetadata.annotations}}

	}

	// Reference to the Module to deploy
	#module!: #Module
	_module: #module & {#config: values}

	#moduleMetadata: #module.metadata

	// Components defined in this module release
	components: #module.#components

	// Module-level policies (if any)
	policies?: [Id=string]: #Policy
	if #module.#policies != _|_ {
		policies: #module.#policies
	}

	// Concrete values (everything closed/concrete)
	// Must satisfy the #config from #module
	// It is unified and validated in the runtime
	_val:   #module.#config & values
	values: _
}

#ModuleReleaseMap: [string]: #ModuleRelease

package core

import (
	cue_uuid "uuid"
	schemas "opmodel.dev/schemas@v1"
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
	#module!:        #Module
	#moduleMetadata: #module.metadata

	_module: #module & {#config: values}

	// Auto-discover all #Secret instances from the resolved config.
	// Groups them by $secretName / $dataKey → K8s Secret resource layout.
	// Empty when #config contains no #Secret fields.
	// The CLI reads this field to generate the opm-secrets component at deploy time.
	// CUE cannot generate that component here due to a core → resources/config import cycle.
	_autoSecrets: (schemas.#AutoSecrets & {#in: _module.#config}).out

	// Components defined in this module release
	components: _module.#components

	// Module-level policies (if any)
	policies?: [Id=string]: #Policy
	if _module.#policies != _|_ {
		policies: _module.#policies
	}

	// Concrete values (everything closed/concrete)
	// Must satisfy the #config from #module
	values: _
}

#ModuleReleaseMap: [string]: #ModuleRelease

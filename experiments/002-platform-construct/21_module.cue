package platform_construct

// Stub #Component — minimal surface for testing demand-side reads in
// #PlatformMatch (#resources, #traits, #claims maps) AND for the slim
// render pipeline (transformer bodies read concrete `spec` values).
#Component: {
	metadata: {
		name!:         #NameType
		resourceName?: #NameType
		labels?:       #LabelsAnnotationsType
		annotations?:  #LabelsAnnotationsType
	}
	#resources?: [FQN=string]: _
	#traits?: [FQN=string]:    _
	#claims?: [string]:        #Claim
	spec?: _
}

// Stub #Module — flat eight-slot shape from 015 (minimum required for the
// experiment: metadata + #defines + #components + #claims).
#Module: {
	apiVersion: "opmodel.dev/core/v1alpha2"
	kind:       "Module"
	metadata: {
		modulePath!:  #ModulePathType
		name!:        #NameType
		version!:     #VersionType
		fqn!:         #ModuleFQNType
		uuid!:        #UUIDType
		description?: string
	}
	#components?: [Id=string]: #Component & {
		metadata: name: string | *Id
	}
	#claims?: [string]: #Claim
	#defines?: {
		resources?: [FQN=string]: #Resource & {metadata: fqn: FQN}
		traits?: [FQN=string]: #Trait & {metadata: fqn: FQN}
		claims?: [FQN=string]: #Claim & {metadata: fqn: FQN}
		transformers?: [FQN=string]: (#ComponentTransformer | #ModuleTransformer) & {metadata: fqn: FQN}
	}
}

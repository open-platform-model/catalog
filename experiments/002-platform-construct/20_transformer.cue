package platform_construct

// Stub two-primitive transformer split (015 TR-D5). Just match-key fields and
// metadata.fqn — no #transform body, since the experiment only exercises the
// #Platform projections, not the render pipeline.

#ComponentTransformer: {
	apiVersion: "opmodel.dev/core/v1alpha2"
	kind:       "ComponentTransformer"
	metadata: {
		modulePath!:  #ModulePathType
		version!:     #MajorVersionType
		name!:        #NameType
		fqn!:         #FQNType
		description?: string
	}
	requiredLabels?: #LabelsAnnotationsType
	optionalLabels?: #LabelsAnnotationsType
	requiredResources?: [FQN=string]: _
	optionalResources?: [FQN=string]: _
	requiredTraits?: [FQN=string]:    _
	optionalTraits?: [FQN=string]:    _
	requiredClaims?: [FQN=string]:    _
	optionalClaims?: [FQN=string]:    _
}

#ModuleTransformer: {
	apiVersion: "opmodel.dev/core/v1alpha2"
	kind:       "ModuleTransformer"
	metadata: {
		modulePath!:  #ModulePathType
		version!:     #MajorVersionType
		name!:        #NameType
		fqn!:         #FQNType
		description?: string
	}
	requiredLabels?: #LabelsAnnotationsType
	optionalLabels?: #LabelsAnnotationsType
	requiredClaims?: [FQN=string]: _
	optionalClaims?: [FQN=string]: _
	requiresComponents?: {
		resources?: [FQN=string]: _
		traits?: [FQN=string]:    _
		claims?: [FQN=string]:    _
	}
}

#TransformerMap: [#FQNType]: #ComponentTransformer | #ModuleTransformer

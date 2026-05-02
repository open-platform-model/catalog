package claims

// Stub #TransformerContext — minimal release + component identity.
//
// component is OPTIONAL here (vs. 002 where it's required). #ModuleTransformer
// fires once per module with no component, so the field must accept absence.
// Component-scope dispatch in 25_render.cue still fills component.name in
// concretely.
#TransformerContext: {
	release: {
		name!:      #NameType
		namespace!: #NameType
	}
	component?: {
		name?: #NameType
	}
}

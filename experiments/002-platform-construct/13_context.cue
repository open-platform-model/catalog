package platform_construct

// Stub #TransformerContext — minimal release + component identity that a
// transformer body can read while rendering. Mirrors the role of the
// production schema (014/03-schema.md) but trimmed: full #ctx with the
// runtime/platform two-layer shape lives in enhancement 016 / experiment 001.
//
// Only what the slim render pipeline needs:
//   - release.{name, namespace} — for metadata.namespace on emitted objects
//   - component.name            — for label / selector generation
#TransformerContext: {
	release: {
		name!:      #NameType
		namespace!: #NameType
	}
	component: {
		name!: #NameType
	}
}

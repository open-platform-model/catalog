package module_context

// Stub #Component — only the fields the experiment exercises:
//   metadata.name, metadata.resourceName?, #names, spec passthrough.
// No #resources / #traits / #blueprints; transformer rendering is out of scope.
#Component: {
	apiVersion: "opmodel.dev/experiments/module_context/v0"
	kind:       "Component"

	metadata: {
		name!: #NameType

		// Override the Kubernetes resource base name for this component.
		// When absent, resourceName defaults to "{release}-{component}".
		// All DNS variants in #ctx.runtime.components cascade from this value.
		resourceName?: #NameType

		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	// Per-component computed names, injected by #ContextBuilder so a component
	// can read its own resourceName / DNS variants without typing its map key.
	// Equal to #ctx.runtime.components[<this component's key>].
	#names: #ComponentNames

	// Open spec — module bodies fill it. Tests assert on shapes inside spec.
	spec: _
}

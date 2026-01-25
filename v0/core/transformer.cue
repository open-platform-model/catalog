package core

// #Transformer: Declares how to convert OPM components into platform-specific resources.
//
// Transformers use label-based matching to determine which components they can handle.
// A transformer matches a component when ALL of the following are true:
//   1. ALL requiredLabels are present on the component with matching values
//   2. ALL requiredResources FQNs exist in component.#resources
//   3. ALL requiredTraits FQNs exist in component.#traits
//   4. ALL requiredPolicies FQNs exist in component.#policies
//
// Component labels are inherited from the union of labels from all attached
// #resources, #traits, and #policies definitions.
#Transformer: {
	apiVersion: "opm.dev/core/v0"
	kind:       "Transformer"

	metadata: {
		apiVersion!: #NameType                          // Example: "opm.dev/transformers/kubernetes@v0"
		name!:       #NameType                          // Example: "DeploymentTransformer"
		fqn:         #FQNType & "\(apiVersion)#\(name)" // Example: "opm.dev/transformers/kubernetes@v0#DeploymentTransformer"

		description!: string // A brief description of what this transformer produces

		// Labels for categorizing this transformer (not used for matching)
		labels?: #LabelsAnnotationsType

		// Annotations for additional transformer metadata
		annotations?: #LabelsAnnotationsType
	}

	// Labels that a component MUST have to match this transformer.
	// Component labels are inherited from the union of labels from all attached
	// #resources, #traits, and #policies.
	//
	// Example: A DeploymentTransformer requires stateless workloads:
	//   requiredLabels: {"core.opm.dev/workload-type": "stateless"}
	//
	// The Container resource defines this label, so components with Container
	// will have it. Transformers requiring "stateful" won't match.
	requiredLabels?: #LabelsAnnotationsType

	// Resources required by this transformer - component MUST include these
	// Map key is the FQN, value is the Resource definition (provides access to #defaults)
	requiredResources: [string]: _

	// Resources optionally used by this transformer - component MAY include these
	// If not provided, defaults from the definition can be used
	optionalResources: [string]: _

	// Traits required by this transformer - component MUST include these
	// Map key is the FQN, value is the Trait definition (provides access to #defaults)
	requiredTraits: [string]: _

	// Traits optionally used by this transformer - component MAY include these
	// If not provided, defaults from the definition can be used
	optionalTraits: [string]: _

	// Transform function
	// IMPORTANT: output must be a list of resources, even if only one resource is generated
	// This allows for consistent handling and concatenation when multiple transformers match
	#transform: {
		#component: #Component
		#context:   #TransformerContext

		output: [...] // Must be a list of provider-specific resources
	}
}

// Map of transformers by fully qualified name
#TransformerMap: [string]: #Transformer

// Provider context passed to transformers
// Simplified: Components now have metadata unified from Module in CUE
#TransformerContext: close({
	// Module name and version
	name: string
})

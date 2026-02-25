package core

// Workload type label key
#LabelWorkloadType: "core.opmodel.dev/workload-type"

#Component: {
	apiVersion: "opmodel.dev/core/v0"
	kind:       "Component"

	metadata: {
		name!: #NameType

		// Component labels - unified from all attached resources, traits
		// Labels are inherited from definitions and used for transformer matching.
		// If definitions have conflicting labels, CUE unification will fail (automatic validation).
		labels: #LabelsAnnotationsType & {
			// Inherit labels from resources
			for _, resource in #resources if resource.metadata.labels != _|_ {
				for lk, lv in resource.metadata.labels {
					(lk): lv
				}
			}

			// Inherit labels from traits
			if #traits != _|_ {
				for _, trait in #traits if trait.metadata.labels != _|_ {
					for lk, lv in trait.metadata.labels {
						(lk): lv
					}
				}
			}
		}

		// Component annotations - unified from all attached resources, traits
		// If definitions have conflicting annotations, CUE unification will fail (automatic validation).
		annotations?: {
			[string]: string | int | bool | [...(string | int | bool)]

			// Inherit annotations from resources
			for _, resource in #resources if resource.metadata.annotations != _|_ {
				for ak, av in resource.metadata.annotations {
					(ak): av
				}
			}

			// Inherit annotations from traits
			if #traits != _|_ {
				for _, trait in #traits if trait.metadata.annotations != _|_ {
					for ak, av in trait.metadata.annotations {
						(ak): av
					}
				}
			}
		}
	}

	// Resources applied for this component
	#resources: #ResourceMap
	// if len(#resources) == 0 {
	// 	error("Component must have at least one resource defined")
	// }

	// Traits applied to this component
	#traits?: #TraitMap

	// Blueprints applied to this component
	#blueprints?: #BlueprintMap

	_allFields: {
		for _, resource in #resources {
			if resource.#spec != _|_ {
				for k, v in resource.#spec {
					(k): v
				}
			}
		}
		if #traits != _|_ {
			for _, trait in #traits {
				if trait.#spec != _|_ {
					for k, v in trait.#spec {
						(k): v
					}
				}
			}
		}
		if #blueprints != _|_ {
			for _, blueprint in #blueprints {
				if blueprint.#spec != _|_ {
					for k, v in blueprint.#spec {
						(k): v
					}
				}
			}
		}
	}

	// Fields exposed by this component (merged from all resources, traits, and blueprints)
	// Automatically turned into a spec.
	// Must be made concrete by the user.
	// Have to do it this way because if we allowed the spec flattened in the root of the component
	// we would have to open the #Module definition which would make it impossible to properly validate.
	spec: close({
		_allFields
	})
}

#ComponentMap: [string]: #Component

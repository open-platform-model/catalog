package core

// Workload type label key
#LabelWorkloadType: "core.opmodel.dev/workload-type"

#Component: close({
	apiVersion: "opmodel.dev/core/v0"
	kind:       "Component"

	metadata: {
		name!: string

		// Component labels - unified from all attached resources, traits
		// Labels are inherited from definitions and used for transformer matching.
		// If definitions have conflicting labels, CUE unification will fail (automatic validation).
		labels: #LabelsAnnotationsType & {
			// Standard label for component name
			"component.opmodel.dev/name": name

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
	// 	_|_
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

	status: {
		resourceCount: len(#resources)
		traitCount?: {if #traits != _|_ {len(#traits)}}
		blueprintCount?: {if #blueprints != _|_ {len(#blueprints)}}
	}
})

#ComponentMap: [string]: #Component

_testComponent: #Component & {
	metadata: {
		name: "basic-component"
		labels: {
			"core.opmodel.dev/workload-type": "stateless"
		}
	}

	#resources: {
		"opmodel.dev/resources/workload@v0/Container": close(#Resource & {
			metadata: {
				apiVersion:  "opmodel.dev/resources/workload@v0"
				name:        "Container"
				description: "A container definition for workloads"
				labels: {
					"core.opmodel.dev/category": "workload"
				}
			}
			// OpenAPIv3-compatible schema defining the structure of the container spec
			#spec: container: {
				// Name of the container
				name!: string

				// Container image (e.g., "nginx:latest")
				image!: string

				// Image pull policy
				imagePullPolicy: "Always" | "IfNotPresent" | "Never" | *"IfNotPresent"

				// Environment variables for the container
				env?: [string]: {
					name:  string
					value: string
				}

				// Command to run in the container
				command?: [...string]

				// Arguments to pass to the command
				args?: [...string]

				// Resource requirements for the container
				resources?: {
					limits?: {
						cpu?:    string
						memory?: string
					}
					requests?: {
						cpu?:    string
						memory?: string
					}
				}
			}
		})
	}

	// Compose resources and traits, providing concrete values for the spec.
	spec: {
		container: {
			name:            "nginx-container"
			image:           "nginx:latest"
			imagePullPolicy: "IfNotPresent"
			env: {
				ENVIRONMENT: {
					name:  "ENVIRONMENT"
					value: "production"
				}
			}
			resources: {
				limits: {
					cpu:    "500m"
					memory: "256Mi"
				}
				requests: {
					cpu:    "250m"
					memory: "128Mi"
				}
			}
		}
	}
}
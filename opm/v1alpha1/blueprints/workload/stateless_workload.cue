package workload

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/opm/v1alpha1/schemas@v1"
	workload_resources "opmodel.dev/opm/v1alpha1/resources/workload@v1"
	workload_traits "opmodel.dev/opm/v1alpha1/traits/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// StatelessWorkload Blueprint Definition
/////////////////////////////////////////////////////////////////

#StatelessWorkloadBlueprint: prim.#Blueprint & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/blueprints/workload"
		version:     "v1"
		name:        "stateless-workload"
		description: "A stateless workload with no requirement for stable identity or storage"
	}

	composedResources: [
		workload_resources.#ContainerResource,
	]

	composedTraits: [
		workload_traits.#ScalingTrait,
	]

	spec: statelessWorkload: schemas.#StatelessWorkloadSchema
}

#StatelessWorkload: component.#Component & {
	metadata: labels: {
		"core.opmodel.dev/workload-type": "stateless"
	}

	#blueprints: (#StatelessWorkloadBlueprint.metadata.fqn): #StatelessWorkloadBlueprint

	workload_resources.#Container
	workload_traits.#Scaling
	workload_traits.#RestartPolicy
	workload_traits.#UpdateStrategy
	workload_traits.#SidecarContainers
	workload_traits.#InitContainers

	// Override spec to propagate values from statelessWorkload
	spec: {
		statelessWorkload: schemas.#StatelessWorkloadSchema
		container:         spec.statelessWorkload.container
		if spec.statelessWorkload.scaling != _|_ {
			scaling: spec.statelessWorkload.scaling
		}
		if spec.statelessWorkload.restartPolicy != _|_ {
			restartPolicy: spec.statelessWorkload.restartPolicy
		}
		if spec.statelessWorkload.updateStrategy != _|_ {
			updateStrategy: spec.statelessWorkload.updateStrategy
		}
		if spec.statelessWorkload.sidecarContainers != _|_ {
			sidecarContainers: spec.statelessWorkload.sidecarContainers
		}
		if spec.statelessWorkload.initContainers != _|_ {
			initContainers: spec.statelessWorkload.initContainers
		}
	}
}

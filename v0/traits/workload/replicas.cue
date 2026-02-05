package workload

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// Replicas Trait Definition
/////////////////////////////////////////////////////////////////

#ReplicasTrait: close(core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/workload@v0"
		name:        "Replicas"
		description: "A trait to specify the number of replicas for a workload"
		labels: {
			"core.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource] // Full CUE reference (not FQN string)

	// Default values for replicas trait
	#defaults: #ReplicasDefaults

	#spec: replicas: schemas.#ReplicasSchema
})

#Replicas: close(core.#Component & {
	#traits: {(#ReplicasTrait.metadata.fqn): #ReplicasTrait}
})

#ReplicasDefaults: schemas.#ReplicasSchema & int | *1

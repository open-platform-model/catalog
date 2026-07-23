package workload

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	workload_resources "opmodel.dev/opm/v1alpha1/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// PodMetadata Trait Definition
/////////////////////////////////////////////////////////////////

// #PodMetadataTrait sets annotations and labels on the POD TEMPLATE of a
// workload (spec.template.metadata), as opposed to #Component.metadata
// annotations/labels which only reach the top-level resource metadata.
//
// This is the channel for pod-scoped metadata that controllers read off the
// running Pod - e.g. k8up's `k8up.io/backupcommand`, Prometheus scrape hints,
// or istio sidecar-injection overrides. Keeping it separate from the
// component-wide annotation bag is deliberate: it lets a component target the
// pod only, without also stamping the annotation onto the Service/PVC/etc. (and
// vice-versa), which matters when the same key means different things on
// different objects (e.g. k8up's pod `backupcommand` vs a PVC `backup: false`).
#PodMetadataTrait: prim.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/traits/workload"
		version:     "v1"
		name:        "pod-metadata"
		description: "A trait to set annotations and labels on the pod template of a workload"
		labels: {
			"trait.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	spec: close({podMetadata: #PodMetadataSchema})
}

#PodMetadata: component.#Component & {
	#traits: {(#PodMetadataTrait.metadata.fqn): #PodMetadataTrait}
}

#PodMetadataSchema: {
	// Annotations applied to spec.template.metadata.annotations on the pod.
	annotations?: [string]: string

	// Labels applied to spec.template.metadata.labels on the pod, merged with
	// the standard component labels (which remain the Service/selector labels).
	labels?: [string]: string
}

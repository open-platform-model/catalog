package transformers

import (
	k8scorev1 "opmodel.dev/schemas/kubernetes/core/v1@v1"
	schemas "opmodel.dev/schemas@v1"
)

// #ToK8sContainer converts an OPM #ContainerSchema to a Kubernetes #Container.
// OPM uses struct-keyed env/ports/volumeMounts; Kubernetes expects lists.
//
// Usage:
//   (#ToK8sContainer & {"in": _container}).out
#ToK8sContainer: {
	X="in": schemas.#ContainerSchema

	out: k8scorev1.#Container & {
		name:            X.name
		image:           X.image.reference
		imagePullPolicy: X.image.pullPolicy
		if X.command != _|_ {
			command: X.command
		}
		if X.args != _|_ {
			args: X.args
		}
		if X.ports != _|_ {
			ports: [for _, p in X.ports {
				name:          p.name
				containerPort: p.targetPort
				protocol:      p.protocol
				if p.hostIP != _|_ {hostIP: p.hostIP}
				if p.hostPort != _|_ {hostPort: p.hostPort}
			}]
		}
		if X.env != _|_ {
			env: [for _, e in X.env {e}]
		}
		if X.resources != _|_ {
			resources: {
				if X.resources.requests != _|_ {
					requests: {
						if X.resources.requests.cpu != _|_ {
							cpu: (schemas.#NormalizeCPU & {in: X.resources.requests.cpu}).out
						}
						if X.resources.requests.memory != _|_ {
							memory: (schemas.#NormalizeMemory & {in: X.resources.requests.memory}).out
						}
					}
				}

				if X.resources.limits != _|_ {
					limits: {
						if X.resources.limits.cpu != _|_ {
							cpu: (schemas.#NormalizeCPU & {in: X.resources.limits.cpu}).out
						}
						if X.resources.limits.memory != _|_ {
							memory: (schemas.#NormalizeMemory & {in: X.resources.limits.memory}).out
						}
					}
				}
			}
		}
		if X.volumeMounts != _|_ {
			volumeMounts: [for _, vm in X.volumeMounts {vm}]
		}
		if X.startupProbe != _|_ {
			startupProbe: X.startupProbe
		}
		if X.livenessProbe != _|_ {
			livenessProbe: X.livenessProbe
		}
		if X.readinessProbe != _|_ {
			readinessProbe: X.readinessProbe
		}
	}
}

// #ToK8sContainers converts a list of OPM containers to Kubernetes containers.
//
// Usage:
//   (#ToK8sContainers & {"in": _initContainers}).out
#ToK8sContainers: {
	X="in": [...schemas.#ContainerSchema]

	out: [for c in X {
		(#ToK8sContainer & {"in": c}).out
	}]
}

_testToK8sContainer: {
	// Example input container
	in: {
		name: "example-container"
		image: {
			repository: "example-image"
			tag:        "latest"
			digest:     ""
		}
		command: ["/bin/example"]
		args: ["--example-arg"]
		ports: {
			http: {
				name:       "http"
				targetPort: 8080
				protocol:   "TCP"
			}
		}
		env: {
			EXAMPLE_ENV_VAR: {
				name:  "EXAMPLE_ENV_VAR"
				value: "example-value"
			}
		}
		resources: {
			requests: {
				cpu:    "100m"
				memory: "128Mi"
			}
			limits: {
				cpu:    "200m"
				memory: "256Mi"
			}
		}
		volumeMounts: {
			exampleVolumeMount: {
				name:      "example-volume"
				mountPath: "/data/example"
			}
		}
	}

	out: (#ToK8sContainer & {"in": in}).out
}

_testToK8sContainers: {
	// Example list of input containers
	in: [
		{
			name: "example-container-1"
			image: {
				repository: "example-image-1"
				tag:        "latest"
				digest:     ""
			}
		},
		{
			name: "example-container-2"
			image: {
				repository: "example-image-2"
				tag:        "latest"
				digest:     ""
			}
		},
	]

	out: (#ToK8sContainers & {"in": in}).out
}

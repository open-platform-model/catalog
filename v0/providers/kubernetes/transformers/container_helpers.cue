package transformers

import (
	k8scorev1 "opmodel.dev/schemas/kubernetes/core/v1@v0"
	schemas "opmodel.dev/schemas@v0"
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
		image:           X.image
		imagePullPolicy: X.imagePullPolicy
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
				if X.resources.cpu != _|_ {
					if X.resources.cpu.request != _|_ {
						requests: cpu: (schemas.#NormalizeCPU & {in: X.resources.cpu.request}).out
					}
					if X.resources.cpu.limit != _|_ {
						limits: cpu: (schemas.#NormalizeCPU & {in: X.resources.cpu.limit}).out
					}
				}
				if X.resources.memory != _|_ {
					if X.resources.memory.request != _|_ {
						requests: memory: (schemas.#NormalizeMemory & {in: X.resources.memory.request}).out
					}
					if X.resources.memory.limit != _|_ {
						limits: memory: (schemas.#NormalizeMemory & {in: X.resources.memory.limit}).out
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
		name:            "example-container"
		image:           "example-image:latest"
		imagePullPolicy: "IfNotPresent"
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
			cpu: {
				request: "100m"
				limit:   "200m"
			}
			memory: {
				request: "128Mi"
				limit:   "256Mi"
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
			name:            "example-container-1"
			image:           "example-image-1:latest"
			imagePullPolicy: "IfNotPresent"
		},
		{
			name:            "example-container-2"
			image:           "example-image-2:latest"
			imagePullPolicy: "IfNotPresent"
		},
	]

	out: (#ToK8sContainers & {"in": in}).out
}

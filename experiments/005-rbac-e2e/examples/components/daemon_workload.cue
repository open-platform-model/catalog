package components

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	workload_resources "opmodel.dev/resources/workload@v1"
	storage_resources "opmodel.dev/resources/storage@v1"
	workload_traits "opmodel.dev/traits/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// Daemon Workload Example
/////////////////////////////////////////////////////////////////

daemonWorkload: core.#Component & {
	metadata: {
		name: "daemon-workload"
		labels: {
			"core.opmodel.dev/workload-type": "daemon"
		}
	}

	// Compose resources and traits using helpers
	workload_resources.#Container
	storage_resources.#Volumes
	workload_traits.#RestartPolicy
	workload_traits.#UpdateStrategy

	_volumes: spec.volumes

	spec: {
		restartPolicy: "Always"
		updateStrategy: {
			type: "RollingUpdate"
			rollingUpdate: {
				maxUnavailable: 1
			}
		}
		container: {
			name: "node-exporter"
			image: {
				repository: string | *"prom/node-exporter"
				tag:        string | *"v1.6.1"
				digest:     string | *""
			}
			ports: {
				metrics: {
					name:       "metrics"
					targetPort: 9100
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
				proc: schemas.#VolumeMountSchema & {
					mountPath: "/host/proc"
					readOnly:  true
				} & _volumes.proc
				sys: schemas.#VolumeMountSchema & {
					mountPath: "/host/sys"
					readOnly:  true
				} & _volumes.sys
			}
			livenessProbe: {
				httpGet: {
					path: "/metrics"
					port: 9100
				}
				initialDelaySeconds: 15
				periodSeconds:       20
			}
			readinessProbe: {
				httpGet: {
					path: "/metrics"
					port: 9100
				}
				initialDelaySeconds: 5
				periodSeconds:       10
			}
		}
		volumes: {
			proc: {
				name: "proc"
				hostPath: path: "/proc"
			}
			sys: {
				name: "sys"
				hostPath: path: "/sys"
			}
		}
	}
}

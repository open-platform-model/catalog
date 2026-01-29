package components

import (
	core "opmodel.dev/core@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
	workload_traits "opmodel.dev/traits/workload@v0"
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
	workload_traits.#RestartPolicy
	workload_traits.#UpdateStrategy
	workload_traits.#HealthCheck

	spec: {
		restartPolicy: "Always"
		updateStrategy: {
			type: "RollingUpdate"
			rollingUpdate: {
				maxUnavailable: 1
			}
		}
		healthCheck: {
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
		container: {
			name:            "node-exporter"
			image:           string | *"prom/node-exporter:v1.6.1"
			imagePullPolicy: "IfNotPresent"
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
				proc: {
					name:      "proc"
					mountPath: "/host/proc"
					readOnly:  true
				}
				sys: {
					name:      "sys"
					mountPath: "/host/sys"
					readOnly:  true
				}
			}
		}
	}
}

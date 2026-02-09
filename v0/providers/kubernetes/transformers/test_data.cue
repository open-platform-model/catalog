package transformers

import (
	core "opmodel.dev/core@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
	workload_traits "opmodel.dev/traits/workload@v0"
	security_traits "opmodel.dev/traits/security@v0"
	network_traits "opmodel.dev/traits/network@v0"
	storage_resources "opmodel.dev/resources/storage@v0"
	config_resources "opmodel.dev/resources/config@v0"
	security_resources "opmodel.dev/resources/security@v0"
)

// Shared test context
_testContext: core.#TransformerContext & {
	#moduleMetadata: {
		name:    "test-module"
		version: "0.1.0"
		labels: {
			"test-context": "true"
		}
	}
	#componentMetadata: {
		name: "test-component"
		labels: {
			"test-component": "true"
		}
	}
	name:      "test-release"
	namespace: "default"
}

// Test component for Deployment (stateless workload with Container)
_testComponent: core.#Component & {
	metadata: {
		name: "test-deployment"
		labels: {
			"core.opmodel.dev/workload-type": "stateless"
		}
	}

	#resources: {
		"opmodel.dev/resources/workload@v0#Container": workload_resources.#ContainerResource
	}

	spec: container: {
		name:  "test-container"
		image: "nginx:latest"
	}
}

// Test component for DaemonSet (daemon workload with Container)
_testDaemonSetComponent: core.#Component & {
	metadata: {
		name: "test-daemonset"
		labels: {
			"core.opmodel.dev/workload-type": "daemon"
		}
	}

	#resources: {
		"opmodel.dev/resources/workload@v0#Container": workload_resources.#ContainerResource
	}

	spec: container: {
		name:  "test-daemon-container"
		image: "fluentd:latest"
	}
}

// Test component for StatefulSet (stateful workload with Container)
_testStatefulSetComponent: core.#Component & {
	metadata: {
		name: "test-statefulset"
		labels: {
			"core.opmodel.dev/workload-type": "stateful"
		}
	}

	#resources: {
		"opmodel.dev/resources/workload@v0#Container": workload_resources.#ContainerResource
	}

	spec: container: {
		name:  "test-stateful-container"
		image: "postgres:15"
	}
}

// Test component for CronJob (scheduled-task workload with Container + CronJobConfig)
_testCronJobComponent: core.#Component & {
	metadata: {
		name: "test-cronjob"
		labels: {
			"core.opmodel.dev/workload-type": "scheduled-task"
		}
	}

	#resources: {
		"opmodel.dev/resources/workload@v0#Container": workload_resources.#ContainerResource
	}

	#traits: {
		"opmodel.dev/traits/workload@v0#CronJobConfig": workload_traits.#CronJobConfigTrait
	}

	spec: {
		container: {
			name:  "test-cron-container"
			image: "busybox:latest"
		}
		cronJobConfig: {
			scheduleCron: "0 * * * *"
		}
	}
}

// Test component for Job (task workload with Container + JobConfig)
_testJobComponent: core.#Component & {
	metadata: {
		name: "test-job"
		labels: {
			"core.opmodel.dev/workload-type": "task"
		}
	}

	#resources: {
		"opmodel.dev/resources/workload@v0#Container": workload_resources.#ContainerResource
	}

	#traits: {
		"opmodel.dev/traits/workload@v0#JobConfig": workload_traits.#JobConfigTrait
	}

	spec: {
		container: {
			name:  "test-job-container"
			image: "busybox:latest"
		}
		jobConfig: {
			completions: 1
			parallelism: 1
		}
	}
}

// Test component for Service (Container + Expose trait)
_testServiceComponent: core.#Component & {
	metadata: {
		name: "test-service"
		labels: {
			"core.opmodel.dev/workload-type": "stateless"
		}
	}

	#resources: {
		"opmodel.dev/resources/workload@v0#Container": workload_resources.#ContainerResource
	}

	#traits: {
		"opmodel.dev/traits/network@v0#Expose": network_traits.#ExposeTrait
	}

	spec: {
		container: {
			name:  "test-web-container"
			image: "nginx:latest"
		}
		expose: {
			type: "ClusterIP"
			ports: {
				http: {
					targetPort: 80
				}
			}
		}
	}
}

// Test component for PVC (Volumes resource)
_testPVCComponent: core.#Component & {
	metadata: {
		name: "test-pvc"
		labels: {
			"core.opmodel.dev/persistence": "true"
		}
	}

	#resources: {
		"opmodel.dev/resources/storage@v0#Volumes": storage_resources.#VolumesResource
	}

	spec: volumes: {
		"data-volume": {
			persistentClaim: {
				size:         "10Gi"
				accessMode:   "ReadWriteOnce"
				storageClass: "standard"
			}
		}
	}
}

// Test component with HealthCheck, Sizing, and SecurityContext traits
_testComponentWithTraits: core.#Component & {
	metadata: {
		name: "test-deployment-with-traits"
		labels: {
			"core.opmodel.dev/workload-type": "stateless"
		}
	}

	#resources: {
		"opmodel.dev/resources/workload@v0#Container": workload_resources.#ContainerResource
	}

	#traits: {
		"opmodel.dev/traits/workload@v0#HealthCheck":     workload_traits.#HealthCheckTrait
		"opmodel.dev/traits/workload@v0#Sizing":          workload_traits.#SizingTrait
		"opmodel.dev/traits/security@v0#SecurityContext": security_traits.#SecurityContextTrait
	}

	spec: {
		container: {
			name:  "test-app"
			image: "myapp:latest"
		}
		healthCheck: {
			livenessProbe: {
				httpGet: {
					path: "/healthz"
					port: 8080
				}
				initialDelaySeconds: 10
				periodSeconds:       5
			}
			readinessProbe: {
				httpGet: {
					path: "/ready"
					port: 8080
				}
			}
		}
		sizing: {
			cpu: {
				request: "100m"
				limit:   "500m"
			}
			memory: {
				request: "128Mi"
				limit:   "256Mi"
			}
		}
		securityContext: {
			runAsNonRoot:             true
			runAsUser:                1000
			runAsGroup:               1000
			readOnlyRootFilesystem:   true
			allowPrivilegeEscalation: false
			capabilities: drop: ["ALL"]
		}
	}
}

_testDeploymentWithTraits: #DeploymentTransformer.#transform & {
	#component: _testComponentWithTraits
	#context:   _testContext
}

// Test component for ConfigMap
_testConfigMapComponent: core.#Component & {
	metadata: {
		name: "test-configmap"
		labels: {}
	}

	#resources: {
		"opmodel.dev/resources/config@v0#ConfigMap": config_resources.#ConfigMapResource
	}

	spec: configMap: {
		data: {
			"app.conf":      "key=value"
			"settings.json": "{}"
		}
	}
}

// Test component for Secret
_testSecretComponent: core.#Component & {
	metadata: {
		name: "test-secret"
		labels: {}
	}

	#resources: {
		"opmodel.dev/resources/config@v0#Secret": config_resources.#SecretResource
	}

	spec: secret: {
		type: "Opaque"
		data: {
			password: "cGFzc3dvcmQ="
		}
	}
}

// Test component for ServiceAccount (WorkloadIdentity resource)
_testServiceAccountComponent: core.#Component & {
	metadata: {
		name: "test-serviceaccount"
		labels: {
			"core.opmodel.dev/workload-type": "stateless"
		}
	}

	#resources: {
		"opmodel.dev/resources/workload@v0#Container":        workload_resources.#ContainerResource
		"opmodel.dev/resources/security@v0#WorkloadIdentity": security_resources.#WorkloadIdentityResource
	}

	spec: {
		container: {
			name:  "test-sa-container"
			image: "myapp:latest"
		}
		workloadIdentity: {
			name:           "my-app"
			automountToken: false
		}
	}
}

// Test component for HPA (stateless with scaling.auto)
_testHPAComponent: core.#Component & {
	metadata: {
		name: "test-hpa"
		labels: {
			"core.opmodel.dev/workload-type": "stateless"
		}
	}

	#resources: {
		"opmodel.dev/resources/workload@v0#Container": workload_resources.#ContainerResource
	}

	#traits: {
		"opmodel.dev/traits/workload@v0#Scaling": workload_traits.#ScalingTrait
	}

	spec: {
		container: {
			name:  "test-hpa-container"
			image: "myapp:latest"
		}
		scaling: {
			count: 1
			auto: {
				min: 2
				max: 10
				metrics: [{
					type: "cpu"
					target: averageUtilization: 80
				}]
			}
		}
	}
}

// Test component for Ingress (HttpRoute trait)
_testIngressComponent: core.#Component & {
	metadata: {
		name: "test-ingress"
		labels: {
			"core.opmodel.dev/workload-type": "stateless"
		}
	}

	#resources: {
		"opmodel.dev/resources/workload@v0#Container": workload_resources.#ContainerResource
	}

	#traits: {
		"opmodel.dev/traits/network@v0#HttpRoute": network_traits.#HttpRouteTrait
	}

	spec: {
		container: {
			name:  "test-ingress-container"
			image: "myapp:latest"
		}
		httpRoute: {
			hostnames: ["app.example.com"]
			ingressClassName: "nginx"
			tls: {
				mode: "Terminate"
				certificateRef: name: "app-tls"
			}
			rules: [{
				matches: [{
					path: {
						value: "/api"
						type:  "Prefix"
					}
				}]
				backendPort: 8080
			}]
		}
	}
}

package transformers

import (
	core "opmodel.dev/core@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
	workload_traits "opmodel.dev/traits/workload@v0"
	network_traits "opmodel.dev/traits/network@v0"
	storage_resources "opmodel.dev/resources/storage@v0"
)

// Shared test context
_testContext: core.#TransformerContext & {
	#moduleMetadata: {
		name:    "test-module"
		version: "0.1.0"
	}
	#componentMetadata: {
		name: "test-component"
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
		"opmodel.dev/traits/networking@v0#Expose": network_traits.#ExposeTrait
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

@if(test)

package workload

import (
	core "opmodel.dev/core@v0"
)

// =============================================================================
// Container Resource Tests
// =============================================================================

// Test: ContainerResource definition structure
_testContainerResourceDef: #ContainerResource & {
	metadata: {
		apiVersion:  "opmodel.dev/resources/workload@v0"
		name:        "container"
		fqn:         "opmodel.dev/resources/workload@v0#Container"
		description: "A container definition for workloads"
	}
}

// Test: Container component helper with stateless workload type
_testContainerComponentStateless: #Container & {
	metadata: {
		name: "test-stateless"
		labels: "core.opmodel.dev/workload-type": "stateless"
	}
	spec: container: {
		name:  "web"
		image: "nginx:latest"
	}
}

// Test: Container component helper with stateful workload type
_testContainerComponentStateful: #Container & {
	metadata: {
		name: "test-stateful"
		labels: "core.opmodel.dev/workload-type": "stateful"
	}
	spec: container: {
		name:  "db"
		image: "postgres:16"
	}
}

// Test: Container component with all supported workload types
_testContainerComponentDaemon: #Container & {
	metadata: {
		name: "test-daemon"
		labels: "core.opmodel.dev/workload-type": "daemon"
	}
	spec: container: {
		name:  "agent"
		image: "fluentd:latest"
	}
}

_testContainerComponentTask: #Container & {
	metadata: {
		name: "test-task"
		labels: "core.opmodel.dev/workload-type": "task"
	}
	spec: container: {
		name:  "migration"
		image: "myapp:latest"
		command: ["./migrate"]
	}
}

_testContainerComponentScheduled: #Container & {
	metadata: {
		name: "test-scheduled"
		labels: "core.opmodel.dev/workload-type": "scheduled-task"
	}
	spec: container: {
		name:  "backup"
		image: "backup:latest"
		command: ["./backup.sh"]
	}
}

// Test: Container with full spec (ports, env, resources, etc.)
_testContainerFullSpec: #Container & {
	metadata: {
		name: "full-container"
		labels: "core.opmodel.dev/workload-type": "stateless"
	}
	spec: container: {
		name:            "web"
		image:           "nginx:1.25"
		imagePullPolicy: "Always"
		ports: http: {
			name:       "http"
			targetPort: 80
		}
		env: ENVIRONMENT: {
			name:  "ENVIRONMENT"
			value: "production"
		}
		command: ["nginx"]
		args: ["-g", "daemon off;"]
		resources: {
			cpu: {
				request: "100m"
				limit:   "500m"
			}
			memory: {
				request: "128Mi"
				limit:   "256Mi"
			}
		}
	}
}

// Test: ContainerDefaults provides IfNotPresent as default
_testContainerDefaults: #ContainerDefaults & {
	name:            "test"
	image:           "test:latest"
	imagePullPolicy: "IfNotPresent"
}

// Test: Container resource is in the right resource map key
_testContainerResourceMapKey: {
	_key: #ContainerResource.metadata.fqn
	_key: "opmodel.dev/resources/workload@v0#Container"
}

// Test: Container component embeds the resource at the correct FQN key
_testContainerResourceEmbed: #Container & {
	metadata: {
		name: "embed-test"
		labels: "core.opmodel.dev/workload-type": "stateless"
	}
	#resources: ("opmodel.dev/resources/workload@v0#Container"): core.#Resource
	spec: container: {
		name:  "test"
		image: "test:latest"
	}
}

// =============================================================================
// Negative Tests
// =============================================================================

// Negative tests moved to testdata/*.yaml files
